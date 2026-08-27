import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;
  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<ReminderSettings> getReminderSettings() => localDataSource.getReminderSettings();

  @override
  Future<void> saveReminderSettings(ReminderSettings settings) =>
      localDataSource.saveReminderSettings(settings);
}
