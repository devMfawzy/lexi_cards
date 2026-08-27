import 'package:flutter/material.dart';
import '../../../../core/rich_text/quill_content.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/flashcard.dart';

class CardListTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CardListTile({
    super.key,
    required this.card,
    required this.onDelete,
    required this.onTap,
  });

  String _stateLabel(CardState state) {
    switch (state) {
      case CardState.newCard:
        return 'New';
      case CardState.learning:
        return 'Learning';
      case CardState.review:
        return 'Review';
      case CardState.relearning:
        return 'Relearning';
    }
  }

  Color _stateColor(CardState state) {
    switch (state) {
      case CardState.newCard:
        return CardStateColors.newCard;
      case CardState.learning:
        return CardStateColors.learning;
      case CardState.review:
        return CardStateColors.review;
      case CardState.relearning:
        return CardStateColors.relearning;
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stateColor = _stateColor(card.state);

    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Container(width: 4, height: 40, decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: BorderRadius.circular(2),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardPreviewLabel(card.front),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cardPreviewLabel(card.back),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_stateLabel(card.state)),
                    labelStyle: TextStyle(color: stateColor, fontSize: 12, fontWeight: FontWeight.w600),
                    backgroundColor: stateColor.withValues(alpha: 0.12),
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
