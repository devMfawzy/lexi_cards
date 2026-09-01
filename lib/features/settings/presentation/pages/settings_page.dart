import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../sync/presentation/bloc/sync_cubit.dart';
import '../bloc/locale_cubit.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            getReminderSettingsUseCase: getIt(),
            saveReminderSettingsUseCase: getIt(),
            notificationService: getIt(),
          )..load(),
        ),
        // The shared instance, so the linked account shown here and the sync
        // screen's state are the same thing.
        BlocProvider.value(value: getIt<SyncCubit>()..load()),
      ],
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  Future<void> _pickTime(BuildContext context, SettingsCubit cubit, int hour, int minute) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) {
      cubit.setTime(picked.hour, picked.minute);
    }
  }

  Future<void> _pickLanguage(BuildContext context, AppLocalizations l10n, Locale? current) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.languageTitle),
        children: [
          RadioGroup<String?>(
            groupValue: current?.languageCode,
            onChanged: (value) => Navigator.of(context).pop(value ?? 'system'),
            child: Column(
              children: [
                RadioListTile<String?>(
                  title: Text(l10n.languageSystemDefault),
                  value: null,
                ),
                RadioListTile<String?>(
                  title: Text(l10n.languageEnglish),
                  value: 'en',
                ),
                RadioListTile<String?>(
                  title: Text(l10n.languageArabic),
                  value: 'ar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    context.read<LocaleCubit>().setLocale(choice == 'system' ? null : Locale(choice));
  }

  String _languageLabel(AppLocalizations l10n, Locale? locale) {
    switch (locale?.languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'ar':
        return l10n.languageArabic;
      default:
        return l10n.languageSystemDefault;
    }
  }

  String? _feedbackMessage(AppLocalizations l10n, SettingsFeedback? feedback) {
    switch (feedback) {
      case SettingsFeedback.reminderPermissionDenied:
        return l10n.reminderPermissionDenied;
      case SettingsFeedback.testPermissionDenied:
        return l10n.testPermissionDenied;
      case SettingsFeedback.testNotificationSent:
        return l10n.testNotificationSent;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          final message = state.errorMessage ?? _feedbackMessage(l10n, state.feedback);
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final cubit = context.read<SettingsCubit>();
          final settings = state.settings;
          final timeLabel =
              TimeOfDay(hour: settings.hour, minute: settings.minute).format(context);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.dailyReminderTitle),
                      subtitle: Text(l10n.dailyReminderSubtitle),
                      value: settings.enabled,
                      onChanged: cubit.setEnabled,
                    ),
                    if (settings.enabled)
                      ListTile(
                        title: Text(l10n.timeLabel),
                        trailing: Text(timeLabel),
                        onTap: () => _pickTime(context, cubit, settings.hour, settings.minute),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(l10n.languageTitle),
                  trailing: Text(_languageLabel(l10n, locale)),
                  onTap: () => _pickLanguage(context, l10n, locale),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(l10n.syncTitle),
                  // Reads the shared cubit rather than the repository so the
                  // linked account shows here without a second round trip.
                  trailing: Text(
                    context.watch<SyncCubit>().state.accountEmail ??
                        l10n.syncNotConnected,
                  ),
                  onTap: () => context.push('/settings/sync'),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: cubit.sendTestNotification,
                child: Text(l10n.sendTestNotification),
              ),
            ],
          );
        },
      ),
    );
  }
}
