import 'package:flutter/material.dart';

class AddCardDialog extends StatefulWidget {
  const AddCardDialog({super.key});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _frontController,
            decoration: const InputDecoration(labelText: 'Front'),
            autofocus: true,
          ),
          TextField(
            controller: _backController,
            decoration: const InputDecoration(labelText: 'Back'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final front = _frontController.text.trim();
            final back = _backController.text.trim();
            if (front.isEmpty || back.isEmpty) return;
            Navigator.of(context).pop((front, back));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
