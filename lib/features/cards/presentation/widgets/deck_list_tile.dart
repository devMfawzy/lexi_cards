import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/decks_state.dart';
import 'deck_name_dialog.dart';

enum _DeckAction { rename, browse, delete }

class DeckListTile extends StatelessWidget {
  final DeckSummary summary;
  final VoidCallback onTap;
  final VoidCallback onStudy;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;

  const DeckListTile({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onStudy,
    required this.onRename,
    required this.onDelete,
  });

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDeckTitle),
        content: Text(l10n.deleteDeckBody(summary.deck.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showActions(BuildContext context, AppLocalizations l10n) async {
    final colorScheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<_DeckAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.renameDeckTitle),
              onTap: () => Navigator.of(sheetContext).pop(_DeckAction.rename),
            ),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: Text(l10n.browseCards),
              onTap: () => Navigator.of(sheetContext).pop(_DeckAction.browse),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(l10n.delete, style: TextStyle(color: colorScheme.error)),
              onTap: () => Navigator.of(sheetContext).pop(_DeckAction.delete),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case _DeckAction.rename:
        final name = await showDialog<String>(
          context: context,
          builder: (_) => DeckNameDialog(initialName: summary.deck.name),
        );
        if (name != null) onRename(name);
      case _DeckAction.browse:
        onTap();
      case _DeckAction.delete:
        if (await _confirmDelete(context, l10n)) onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(summary.deck.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, l10n),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onLongPress: () => _showActions(context, l10n),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.deck.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatPill(
                              label: l10n.dueCount(summary.dueCount),
                              color: colorScheme.primaryContainer,
                              onColor: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: l10n.newCount(summary.newCount),
                              color: colorScheme.secondaryContainer,
                              onColor: colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_fill, color: colorScheme.primary, size: 36),
                    tooltip: l10n.study,
                    onPressed: onStudy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;

  const _StatPill({required this.label, required this.color, required this.onColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: onColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
