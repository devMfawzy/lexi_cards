import 'package:equatable/equatable.dart';
import '../../domain/entities/reminder_settings.dart';

/// Known, translatable feedback messages. Kept as an enum rather than a
/// literal string because the cubit has no `BuildContext` and can't call
/// `AppLocalizations.of(context)` — the page maps this to text when it
/// builds the SnackBar. Genuinely unexpected errors still go through
/// [SettingsState.errorMessage] as a raw (untranslated) `e.toString()`.
enum SettingsFeedback { reminderPermissionDenied, testPermissionDenied, testNotificationSent }

class SettingsState extends Equatable {
  final ReminderSettings settings;
  final bool isLoading;
  final String? errorMessage;
  final SettingsFeedback? feedback;

  const SettingsState({
    this.settings = ReminderSettings.disabled,
    this.isLoading = false,
    this.errorMessage,
    this.feedback,
  });

  SettingsState copyWith({
    ReminderSettings? settings,
    bool? isLoading,
    String? errorMessage,
    SettingsFeedback? feedback,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      feedback: feedback,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading, errorMessage, feedback];
}
