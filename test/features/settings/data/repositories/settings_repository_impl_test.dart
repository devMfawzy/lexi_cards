import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lexi_cards/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:lexi_cards/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lexi_cards/features/settings/domain/entities/reminder_settings.dart';

void main() {
  late SettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepositoryImpl(localDataSource: SettingsLocalDataSourceImpl());
  });

  test('returns disabled defaults when nothing has been saved yet', () async {
    final settings = await repository.getReminderSettings();
    expect(settings, ReminderSettings.disabled);
  });

  test('round-trips a saved reminder setting', () async {
    const settings = ReminderSettings(enabled: true, hour: 21, minute: 15);

    await repository.saveReminderSettings(settings);
    final loaded = await repository.getReminderSettings();

    expect(loaded, settings);
  });

  test('persists across repository instances backed by the same prefs store', () async {
    await repository.saveReminderSettings(const ReminderSettings(enabled: true, hour: 7, minute: 45));

    final second = SettingsRepositoryImpl(localDataSource: SettingsLocalDataSourceImpl());
    final loaded = await second.getReminderSettings();

    expect(loaded, const ReminderSettings(enabled: true, hour: 7, minute: 45));
  });
}
