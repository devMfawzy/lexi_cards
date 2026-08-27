import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/rich_text/quill_content.dart';
import '../../../../core/widgets/rich_text_editor_field.dart';

/// Create or edit a card's front/back. Pass [initialFront]/[initialBack]
/// (stored Delta JSON, or legacy plain text) to edit an existing card;
/// leave them null to create a new one. Pops a `(front, back)` tuple of
/// Delta JSON strings, or null if cancelled.
class CardEditorDialog extends StatefulWidget {
  final String? initialFront;
  final String? initialBack;

  const CardEditorDialog({super.key, this.initialFront, this.initialBack});

  bool get isEditing => initialFront != null;

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  late final QuillController _frontController = QuillController(
    document: documentFromStored(widget.initialFront ?? ''),
    selection: const TextSelection.collapsed(offset: 0),
  );
  late final QuillController _backController = QuillController(
    document: documentFromStored(widget.initialBack ?? ''),
    selection: const TextSelection.collapsed(offset: 0),
  );

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit card' : 'New card'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichTextEditorField(controller: _frontController, label: 'Front'),
              const SizedBox(height: 12),
              RichTextEditorField(controller: _backController, label: 'Back'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final front = deltaJsonFromDocument(_frontController.document);
            final back = deltaJsonFromDocument(_backController.document);
            if (isContentBlank(front) || isContentBlank(back)) return;
            Navigator.of(context).pop((front, back));
          },
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
