import 'package:flutter/material.dart';
import '../../domain/entities/flashcard.dart';

class CardListTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onDelete;

  const CardListTile({
    super.key,
    required this.card,
    required this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(card.front),
      subtitle: Text(card.back),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(label: Text(_stateLabel(card.state))),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
