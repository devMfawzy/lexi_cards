import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/sync/cloud_storage.dart';
import '../../data/sync_snapshot_codec.dart';
import '../../domain/repositories/sync_repository.dart';
import 'sync_state.dart';

/// Owns the linked account and the sync run.
///
/// A DI singleton rather than created per page, for the same reason
/// `LocaleCubit` is: the linked account is app-wide state. Settings shows it,
/// the sync page acts on it, and a sync started from one shouldn't be lost by
/// navigating to the other.
class SyncCubit extends Cubit<SyncState> {
  final CloudStorage cloudStorage;
  final SyncRepository syncRepository;
  final DateTime Function() _now;

  SyncCubit({
    required this.cloudStorage,
    required this.syncRepository,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const SyncState());

  /// Re-establishes a previously linked account without prompting.
  Future<void> load() async {
    try {
      final account = await cloudStorage.restoreAccount();
      emit(state.copyWith(
        accountEmail: account?.email,
        clearAccount: account == null,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> link() async {
    emit(state.copyWith(status: SyncStatus.working));
    try {
      final account = await cloudStorage.linkAccount();
      if (account == null) {
        // The user dismissed the sheet. Not an error, and not worth a message.
        emit(state.copyWith(status: SyncStatus.idle));
        return;
      }
      emit(state.copyWith(
        status: SyncStatus.idle,
        accountEmail: account.email,
        feedback: SyncFeedback.linked,
      ));
    } catch (e) {
      emit(state.copyWith(status: SyncStatus.idle, errorMessage: e.toString()));
    }
  }

  Future<void> unlink() async {
    try {
      await cloudStorage.unlinkAccount();
      emit(state.copyWith(clearAccount: true, feedback: SyncFeedback.unlinked));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> syncNow() async {
    if (state.status == SyncStatus.working) return;
    emit(state.copyWith(status: SyncStatus.working));
    try {
      final outcome = await syncRepository.sync();
      emit(state.copyWith(
        status: SyncStatus.idle,
        lastSyncedAt: _now(),
        feedback: outcome.isUpToDate
            ? SyncFeedback.alreadyUpToDate
            : SyncFeedback.syncedWithChanges,
        outcome: outcome.isUpToDate ? null : outcome,
      ));
    } on NotLinkedException {
      emit(state.copyWith(
        status: SyncStatus.idle,
        clearAccount: true,
        feedback: SyncFeedback.notLinked,
      ));
    } on RemoteChangedException {
      // Another device kept writing throughout. Retrying immediately would
      // likely lose the same race again, so this asks the user to try later
      // rather than spinning.
      emit(state.copyWith(status: SyncStatus.idle, feedback: SyncFeedback.remoteBusy));
    } on UnsupportedSnapshotVersionException {
      emit(state.copyWith(
        status: SyncStatus.idle,
        feedback: SyncFeedback.snapshotTooNew,
      ));
    } catch (e) {
      emit(state.copyWith(status: SyncStatus.idle, errorMessage: e.toString()));
    }
  }
}
