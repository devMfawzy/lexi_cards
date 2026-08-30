import '../entities/reminder_settings.dart';

abstract class SettingsRepository {
  Future<ReminderSettings> getReminderSettings();
  Future<void> saveReminderSettings(ReminderSettings settings);

  /// The persisted UI language, as an ISO 639-1 code (e.g. `'ar'`), or null
  /// to follow the device's system language.
  Future<String?> getLanguageCode();
  Future<void> saveLanguageCode(String? languageCode);
}
