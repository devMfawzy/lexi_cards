import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/sync_cubit.dart';
import '../bloc/sync_state.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SyncCubit>()..load(),
      child: const _SyncView(),
    );
  }
}

class _SyncView extends StatelessWidget {
  const _SyncView();

  String? _feedbackMessage(AppLocalizations l10n, SyncState state) {
    switch (state.feedback) {
      case SyncFeedback.linked:
        return l10n.syncConnected;
      case SyncFeedback.unlinked:
        return l10n.syncDisconnected;
      case SyncFeedback.alreadyUpToDate:
        return l10n.syncUpToDate;
      case SyncFeedback.syncedWithChanges:
        final outcome = state.outcome;
        final total = outcome == null
            ? 0
            : outcome.decksChanged +
                outcome.cardsChanged +
                outcome.reviewsAdded +
                outcome.recordsRemoved;
        return l10n.syncChangesApplied(total);
      case SyncFeedback.notLinked:
        return l10n.syncNeedsAccount;
      case SyncFeedback.remoteBusy:
        return l10n.syncRemoteBusy;
      case SyncFeedback.snapshotTooNew:
        return l10n.syncSnapshotTooNew;
      case null:
        return null;
    }
  }

  Future<void> _confirmDisconnect(BuildContext context, AppLocalizations l10n) async {
    final cubit = context.read<SyncCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.syncDisconnect),
        content: Text(l10n.syncUninstallWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.syncDisconnect),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.unlink();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: BlocConsumer<SyncCubit, SyncState>(
        listener: (context, state) {
          final message = state.errorMessage ?? _feedbackMessage(l10n, state);
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<SyncCubit>();
          final busy = state.status == SyncStatus.working;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.syncExplainer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                // One row rather than two: the account and when it last synced
                // are a single fact about the connection, and stacking them as
                // separate list tiles left a gap that read as a missing item.
                child: ListTile(
                  title: Text(l10n.syncAccountLabel),
                  isThreeLine: state.isLinked,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.accountEmail ?? l10n.syncNotConnected),
                      if (state.isLinked)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            state.lastSyncedAt == null
                                ? l10n.syncNever
                                : l10n.syncLastSynced(
                                    DateFormat.yMMMd(
                                      Localizations.localeOf(context).toString(),
                                    ).add_jm().format(state.lastSyncedAt!),
                                  ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!state.isLinked)
                FilledButton(
                  onPressed: busy ? null : cubit.link,
                  child: Text(l10n.syncConnectAccount),
                )
              else ...[
                FilledButton(
                  onPressed: busy ? null : cubit.syncNow,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.syncNow),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: busy ? null : () => _confirmDisconnect(context, l10n),
                  child: Text(l10n.syncDisconnect),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
