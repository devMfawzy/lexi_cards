import 'package:equatable/equatable.dart';

class ReminderSettings extends Equatable {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({required this.enabled, required this.hour, required this.minute});

  static const disabled = ReminderSettings(enabled: false, hour: 9, minute: 0);

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  List<Object?> get props => [enabled, hour, minute];
}
