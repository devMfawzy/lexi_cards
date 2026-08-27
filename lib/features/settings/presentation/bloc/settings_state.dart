import 'package:equatable/equatable.dart';
import '../../domain/entities/reminder_settings.dart';

class SettingsState extends Equatable {
  final ReminderSettings settings;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  const SettingsState({
    this.settings = ReminderSettings.disabled,
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  SettingsState copyWith({
    ReminderSettings? settings,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading, errorMessage, infoMessage];
}
