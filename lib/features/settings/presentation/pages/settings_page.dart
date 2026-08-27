import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        getReminderSettingsUseCase: getIt(),
        saveReminderSettingsUseCase: getIt(),
        notificationService: getIt(),
      )..load(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          final message = state.errorMessage ?? state.infoMessage;
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
                      title: const Text('Daily reminder'),
                      subtitle: const Text('Get nudged to review your due cards'),
                      value: settings.enabled,
                      onChanged: cubit.setEnabled,
                    ),
                    if (settings.enabled)
                      ListTile(
                        title: const Text('Time'),
                        trailing: Text(timeLabel),
                        onTap: () => _pickTime(context, cubit, settings.hour, settings.minute),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: cubit.sendTestNotification,
                child: const Text('Send test notification'),
              ),
            ],
          );
        },
      ),
    );
  }
}
