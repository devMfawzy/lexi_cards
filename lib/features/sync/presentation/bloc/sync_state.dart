import 'package:equatable/equatable.dart';

import '../../domain/repositories/sync_repository.dart';

enum SyncStatus { idle, working }

/// Translatable outcomes as an enum, since the cubit has no `BuildContext` to
/// localize with. Same pattern as `SettingsFeedback`.
enum SyncFeedback {
  linked,
  unlinked,
  syncedWithChanges,
  alreadyUpToDate,
  notLinked,
  remoteBusy,
  snapshotTooNew,
}

class SyncState extends Equatable {
  final SyncStatus status;
  final String? accountEmail;
  final DateTime? lastSyncedAt;

  /// Cleared on every emit, so a SnackBar fires exactly once.
  final SyncFeedback? feedback;
  final String? errorMessage;

  /// Detail for [SyncFeedback.syncedWithChanges].
  final SyncOutcome? outcome;

  const SyncState({
    this.status = SyncStatus.idle,
    this.accountEmail,
    this.lastSyncedAt,
    this.feedback,
    this.errorMessage,
    this.outcome,
  });

  bool get isLinked => accountEmail != null;

  /// [feedback], [errorMessage] and [outcome] are assigned unconditionally —
  /// carrying them forward would re-fire the message on the next state change.
  SyncState copyWith({
    SyncStatus? status,
    String? accountEmail,
    bool clearAccount = false,
    DateTime? lastSyncedAt,
    SyncFeedback? feedback,
    String? errorMessage,
    SyncOutcome? outcome,
  }) => SyncState(
    status: status ?? this.status,
    accountEmail: clearAccount ? null : (accountEmail ?? this.accountEmail),
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    feedback: feedback,
    errorMessage: errorMessage,
    outcome: outcome,
  );

  @override
  List<Object?> get props => [status, accountEmail, lastSyncedAt, feedback, errorMessage, outcome];
}
