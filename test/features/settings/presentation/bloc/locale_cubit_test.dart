import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/features/settings/domain/repositories/settings_repository.dart';
import 'package:lexi_cards/features/settings/presentation/bloc/locale_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  LocaleCubit buildCubit() => LocaleCubit(repository: repository);

  test('starts as null (system default) before load', () {
    expect(buildCubit().state, isNull);
  });

  group('load', () {
    blocTest<LocaleCubit, Locale?>(
      'emits null when no language code is persisted',
      build: () {
        when(() => repository.getLanguageCode()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [null],
    );

    blocTest<LocaleCubit, Locale?>(
      'emits the persisted locale',
      build: () {
        when(() => repository.getLanguageCode()).thenAnswer((_) async => 'ar');
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [const Locale('ar')],
    );
  });

  group('setLocale', () {
    blocTest<LocaleCubit, Locale?>(
      'persists and emits the chosen locale',
      build: () {
        when(() => repository.saveLanguageCode(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.setLocale(const Locale('ar')),
      expect: () => [const Locale('ar')],
      verify: (_) {
        verify(() => repository.saveLanguageCode('ar')).called(1);
      },
    );

    blocTest<LocaleCubit, Locale?>(
      'persists and emits null for system default',
      build: () {
        when(() => repository.saveLanguageCode(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      seed: () => const Locale('ar'),
      act: (cubit) => cubit.setLocale(null),
      expect: () => [null],
      verify: (_) {
        verify(() => repository.saveLanguageCode(null)).called(1);
      },
    );
  });
}
