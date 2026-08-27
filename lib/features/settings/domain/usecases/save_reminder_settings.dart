import '../entities/reminder_settings.dart';
import '../repositories/settings_repository.dart';

class SaveReminderSettings {
  final SettingsRepository repository;
  SaveReminderSettings(this.repository);

  Future<void> call(ReminderSettings settings) => repository.saveReminderSettings(settings);
}
