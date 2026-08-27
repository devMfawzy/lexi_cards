import '../entities/reminder_settings.dart';

abstract class SettingsRepository {
  Future<ReminderSettings> getReminderSettings();
  Future<void> saveReminderSettings(ReminderSettings settings);
}
