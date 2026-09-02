import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../rich_text/quill_content.dart';
import 'quill_image_provider_cache.dart';

/// Read-only rendering of a card's stored (Delta JSON or legacy plain-text)
/// content. Wrapped in [IgnorePointer] since it's display-only — that also
/// keeps the read-only editor's own gesture recognizers from stealing taps
/// meant for whatever wraps this (e.g. the flip card's tap-to-reveal).
class RichTextViewer extends StatefulWidget {
  final String stored;

  const RichTextViewer({super.key, required this.stored});

  @override
  State<RichTextViewer> createState() => _RichTextViewerState();
}

class _RichTextViewerState extends State<RichTextViewer> {
  late QuillController _controller = _buildController(widget.stored);

  QuillController _buildController(String stored) => QuillController(
    document: documentFromStored(stored),
    selection: const TextSelection.collapsed(offset: 0),
    readOnly: true,
  );

  @override
  void didUpdateWidget(covariant RichTextViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stored != oldWidget.stored) {
      _controller.dispose();
      _controller = _buildController(widget.stored);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: QuillEditor.basic(
        controller: _controller,
        config: QuillEditorConfig(
          scrollable: false,
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: FlutterQuillEmbeds.editorBuilders(
            videoEmbedConfig: null,
            imageEmbedConfig: QuillEditorImageEmbedConfig(
              imageProviderBuilder: cachedQuillImageProvider,
            ),
          ),
        ),
      ),
    );
  }
}
