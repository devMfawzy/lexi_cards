import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/settings_repository.dart';

/// App-wide current locale (null = follow the device's system language).
///
/// Unlike every other cubit in this app, this one is a DI singleton
/// (`getIt.registerLazySingleton`) rather than created fresh per page —
/// locale genuinely is global state that has to live above `MaterialApp`
/// and be reachable from the Settings screen at the same time.
class LocaleCubit extends Cubit<Locale?> {
  final SettingsRepository repository;

  LocaleCubit({required this.repository}) : super(null);

  Future<void> load() async {
    final languageCode = await repository.getLanguageCode();
    emit(languageCode == null ? null : Locale(languageCode));
  }

  Future<void> setLocale(Locale? locale) async {
    await repository.saveLanguageCode(locale?.languageCode);
    emit(locale);
  }
}
