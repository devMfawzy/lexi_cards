import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/core/sync/cloud_storage.dart';
import 'package:lexi_cards/features/sync/data/sync_snapshot_codec.dart';
import 'package:lexi_cards/features/sync/domain/repositories/sync_repository.dart';
import 'package:lexi_cards/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:lexi_cards/features/sync/presentation/bloc/sync_state.dart';

class MockCloudStorage extends Mock implements CloudStorage {}

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late MockCloudStorage cloudStorage;
  late MockSyncRepository syncRepository;

  final fixedNow = DateTime.utc(2026, 9, 1, 12);

  SyncCubit buildCubit() => SyncCubit(
        cloudStorage: cloudStorage,
        syncRepository: syncRepository,
        now: () => fixedNow,
      );

  setUp(() {
    cloudStorage = MockCloudStorage();
    syncRepository = MockSyncRepository();
    when(() => cloudStorage.restoreAccount()).thenAnswer((_) async => null);
  });

  group('load', () {
    blocTest<SyncCubit, SyncState>(
      'restores a previously linked account without prompting',
      build: () {
        when(() => cloudStorage.restoreAccount())
            .thenAnswer((_) async => const CloudAccount('me@example.com'));
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.accountEmail, 'me@example.com');
        expect(cubit.state.isLinked, isTrue);
        verifyNever(() => cloudStorage.linkAccount());
      },
    );

    blocTest<SyncCubit, SyncState>(
      'stays unlinked when there is nothing to restore',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isLinked, isFalse),
    );
  });

  group('link', () {
    blocTest<SyncCubit, SyncState>(
      'stores the account and confirms',
      build: () {
        when(() => cloudStorage.linkAccount())
            .thenAnswer((_) async => const CloudAccount('me@example.com'));
        return buildCubit();
      },
      act: (cubit) => cubit.link(),
      verify: (cubit) {
        expect(cubit.state.accountEmail, 'me@example.com');
        expect(cubit.state.feedback, SyncFeedback.linked);
        expect(cubit.state.status, SyncStatus.idle);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'dismissing the sign-in sheet is not an error and says nothing',
      build: () {
        when(() => cloudStorage.linkAccount()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.link(),
      verify: (cubit) {
        expect(cubit.state.isLinked, isFalse);
        expect(cubit.state.feedback, isNull);
        expect(cubit.state.errorMessage, isNull);
      },
    );
  });

  group('unlink', () {
    blocTest<SyncCubit, SyncState>(
      'clears the account',
      build: () {
        when(() => cloudStorage.unlinkAccount()).thenAnswer((_) async {});
        when(() => cloudStorage.restoreAccount())
            .thenAnswer((_) async => const CloudAccount('me@example.com'));
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.unlink();
      },
      verify: (cubit) {
        expect(cubit.state.isLinked, isFalse);
        expect(cubit.state.feedback, SyncFeedback.unlinked);
      },
    );
  });

  group('syncNow', () {
    blocTest<SyncCubit, SyncState>(
      'reports what changed and records the time',
      build: () {
        when(() => syncRepository.sync())
            .thenAnswer((_) async => const SyncOutcome(cardsChanged: 3));
        return buildCubit();
      },
      act: (cubit) => cubit.syncNow(),
      verify: (cubit) {
        expect(cubit.state.feedback, SyncFeedback.syncedWithChanges);
        expect(cubit.state.outcome?.cardsChanged, 3);
        expect(cubit.state.lastSyncedAt, fixedNow);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'says so plainly when nothing had changed',
      build: () {
        when(() => syncRepository.sync()).thenAnswer((_) async => const SyncOutcome());
        return buildCubit();
      },
      act: (cubit) => cubit.syncNow(),
      verify: (cubit) {
        expect(cubit.state.feedback, SyncFeedback.alreadyUpToDate);
        expect(cubit.state.outcome, isNull);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'a revoked account is dropped so the UI offers to reconnect',
      build: () {
        when(() => cloudStorage.restoreAccount())
            .thenAnswer((_) async => const CloudAccount('me@example.com'));
        when(() => syncRepository.sync()).thenThrow(const NotLinkedException());
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.syncNow();
      },
      verify: (cubit) {
        expect(cubit.state.isLinked, isFalse);
        expect(cubit.state.feedback, SyncFeedback.notLinked);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'a remote that kept moving asks the user to retry rather than spinning',
      build: () {
        when(() => syncRepository.sync()).thenThrow(const RemoteChangedException());
        return buildCubit();
      },
      act: (cubit) => cubit.syncNow(),
      verify: (cubit) {
        expect(cubit.state.feedback, SyncFeedback.remoteBusy);
        expect(cubit.state.status, SyncStatus.idle);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'data from a newer app version is reported as such, not as a crash',
      build: () {
        when(() => syncRepository.sync())
            .thenThrow(const UnsupportedSnapshotVersionException(99));
        return buildCubit();
      },
      act: (cubit) => cubit.syncNow(),
      verify: (cubit) => expect(cubit.state.feedback, SyncFeedback.snapshotTooNew),
    );

    blocTest<SyncCubit, SyncState>(
      'an unexpected failure surfaces rather than being swallowed',
      build: () {
        when(() => syncRepository.sync()).thenThrow(Exception('network down'));
        return buildCubit();
      },
      act: (cubit) => cubit.syncNow(),
      verify: (cubit) {
        expect(cubit.state.errorMessage, contains('network down'));
        expect(cubit.state.status, SyncStatus.idle);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'a second tap while syncing is ignored',
      build: () {
        when(() => syncRepository.sync()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return const SyncOutcome();
        });
        return buildCubit();
      },
      act: (cubit) async {
        final first = cubit.syncNow();
        await cubit.syncNow();
        await first;
      },
      verify: (_) => verify(() => syncRepository.sync()).called(1),
    );
  });
}
