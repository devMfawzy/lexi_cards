import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Prompts for a deck name — used both to create a new deck and to rename
/// an existing one, distinguished by whether [initialName] is set.
class DeckNameDialog extends StatefulWidget {
  final String? initialName;

  const DeckNameDialog({super.key, this.initialName});

  @override
  State<DeckNameDialog> createState() => _DeckNameDialogState();
}

class _DeckNameDialogState extends State<DeckNameDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRename = widget.initialName != null;
    return AlertDialog(
      title: Text(isRename ? l10n.renameDeckTitle : l10n.newDeckTitle),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(labelText: l10n.deckNameLabel),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(name);
          },
          child: Text(isRename ? l10n.save : l10n.create),
        ),
      ],
    );
  }
}
