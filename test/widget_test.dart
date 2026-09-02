import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/core/di/injection_container.dart';
import 'package:lexi_cards/core/sync/cloud_storage.dart';
import 'package:lexi_cards/features/cards/domain/entities/deck.dart';
import 'package:lexi_cards/features/cards/domain/usecases/create_deck.dart';
import 'package:lexi_cards/features/cards/domain/usecases/delete_deck.dart';
import 'package:lexi_cards/features/cards/domain/usecases/get_cards.dart';
import 'package:lexi_cards/features/cards/domain/usecases/get_decks.dart';
import 'package:lexi_cards/features/cards/domain/usecases/rename_deck.dart';
import 'package:lexi_cards/features/cards/presentation/pages/decks_page.dart';
import 'package:lexi_cards/features/sync/domain/repositories/sync_repository.dart';
import 'package:lexi_cards/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:lexi_cards/l10n/app_localizations.dart';

class MockGetDecks extends Mock implements GetDecks {}

class MockCreateDeck extends Mock implements CreateDeck {}

class MockRenameDeck extends Mock implements RenameDeck {}

class MockDeleteDeck extends Mock implements DeleteDeck {}

class MockGetCards extends Mock implements GetCards {}

class MockCloudStorage extends Mock implements CloudStorage {}

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late MockGetDecks mockGetDecks;
  late MockGetCards mockGetCards;
  late MockSyncRepository mockSyncRepository;
  late SyncCubit syncCubit;

  setUp(() {
    mockGetDecks = MockGetDecks();
    mockGetCards = MockGetCards();
    mockSyncRepository = MockSyncRepository();
    when(() => mockGetDecks()).thenAnswer((_) async => <Deck>[]);
    when(() => mockGetCards(any())).thenAnswer((_) async => []);

    syncCubit = SyncCubit(cloudStorage: MockCloudStorage(), syncRepository: mockSyncRepository);

    getIt.registerFactory<GetDecks>(() => mockGetDecks);
    getIt.registerFactory<CreateDeck>(() => MockCreateDeck());
    getIt.registerFactory<RenameDeck>(() => MockRenameDeck());
    getIt.registerFactory<DeleteDeck>(() => MockDeleteDeck());
    getIt.registerFactory<GetCards>(() => mockGetCards);
    getIt.registerSingleton<SyncCubit>(syncCubit);
  });

  tearDown(() => getIt.reset());

  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('Decks page shows empty state when there are no decks', (tester) async {
    await tester.pumpWidget(wrap(const DecksPage()));
    await tester.pump();

    expect(find.text('My Decks'), findsOneWidget);
    expect(find.text('No decks yet. Tap + to create one.'), findsOneWidget);
  });

  testWidgets('the empty state can still be pulled to refresh', (tester) async {
    // Someone who has just linked an account sees an empty list and naturally
    // pulls it. A bare centred column has nothing to pull on, leaving them
    // stuck with no way to retry.
    await tester.pumpWidget(wrap(const DecksPage()));
    await tester.pump();

    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(find.text('No decks yet. Tap + to create one.'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    verify(() => mockGetDecks()).called(greaterThan(1));
  });

  testWidgets('the deck list reloads when a sync writes something', (tester) async {
    // Sync writes to the database directly while this page sits underneath the
    // sync screen, so without this the user comes back to the list they had
    // before they ever linked an account.
    when(
      () => mockSyncRepository.sync(),
    ).thenAnswer((_) async => const SyncOutcome(decksChanged: 2));

    await tester.pumpWidget(wrap(const DecksPage()));
    await tester.pump();
    clearInteractions(mockGetDecks);

    await syncCubit.syncNow();
    await tester.pumpAndSettle();

    verify(() => mockGetDecks()).called(1);
  });

  testWidgets('the deck list reloads after returning from a pushed route', (tester) async {
    // Reviewing changes what's due and browsing a deck can add or delete
    // cards, so the counts here are stale the moment either screen opens. This
    // page stays mounted underneath, so nothing else would tell it.
    when(
      () => mockGetDecks(),
    ).thenAnswer((_) async => [Deck(id: 'd1', name: 'Spanish', createdAt: DateTime.utc(2026))]);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DecksPage()),
        GoRoute(
          path: '/decks/:id/review',
          builder: (_, _) => const Scaffold(body: Text('reviewing')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    clearInteractions(mockGetDecks);

    await tester.tap(find.byIcon(Icons.play_circle_fill).last);
    await tester.pumpAndSettle();
    expect(find.text('reviewing'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    verify(() => mockGetDecks()).called(1);
  });

  testWidgets('a sync that changed nothing does not reload the list', (tester) async {
    when(() => mockSyncRepository.sync()).thenAnswer((_) async => const SyncOutcome());

    await tester.pumpWidget(wrap(const DecksPage()));
    await tester.pump();
    clearInteractions(mockGetDecks);

    await syncCubit.syncNow();
    await tester.pumpAndSettle();

    verifyNever(() => mockGetDecks());
  });
}
