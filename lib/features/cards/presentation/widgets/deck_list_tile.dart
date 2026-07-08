import 'package:flutter/material.dart';
import '../bloc/decks_state.dart';

class DeckListTile extends StatelessWidget {
  final DeckSummary summary;
  final VoidCallback onTap;
  final VoidCallback onStudy;
  final VoidCallback onDelete;

  const DeckListTile({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onStudy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(summary.deck.name),
      subtitle: Text('${summary.dueCount} due, ${summary.newCount} new'),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Study',
            onPressed: onStudy,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
