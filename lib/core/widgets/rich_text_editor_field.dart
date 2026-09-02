import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../../l10n/app_localizations.dart';
import '../rich_text/quill_content.dart';
import 'quill_image_provider_cache.dart';

/// A labeled, boxed rich-text input: a curated Quill toolbar (bold, italic,
/// underline, color) above an inline editor. The caller owns [controller]'s
/// lifecycle (create it alongside the other field, dispose it in the same
/// place the old [TextEditingController]s were disposed).
class RichTextEditorField extends StatefulWidget {
  final QuillController controller;
  final String label;

  const RichTextEditorField({super.key, required this.controller, required this.label});

  @override
  State<RichTextEditorField> createState() => _RichTextEditorFieldState();
}

class _RichTextEditorFieldState extends State<RichTextEditorField> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Converts a picked image (local path or pasted link) into what actually
  /// gets embedded, then inserts it at the current selection — the same
  /// mechanics as the (deprecated) `insertImageBlock` extension, written out
  /// directly to avoid depending on a deprecated API.
  Future<void> _insertPickedImage(String imageUrl, QuillController controller) async {
    final String source;
    try {
      source = await imageEmbedSourceFor(imageUrl);
    } on ImageTooLargeException {
      // Refusing is the honest outcome: the image lives inline in the card,
      // so silently inlining an oversized one would bloat the record itself.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.imageTooLarge)));
      return;
    }
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;
    controller
      ..skipRequestKeyboard = true
      ..replaceText(index, length, BlockEmbed.image(source), null)
      ..moveCursorToPosition(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              widget.label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          QuillSimpleToolbar(
            controller: widget.controller,
            config: QuillSimpleToolbarConfig(
              multiRowsDisplay: false,
              showDividers: false,
              showFontFamily: false,
              showFontSize: false,
              showBoldButton: true,
              showItalicButton: true,
              showSmallButton: false,
              showUnderLineButton: true,
              showStrikeThrough: false,
              showInlineCode: false,
              showColorButton: true,
              showBackgroundColorButton: false,
              showClearFormat: false,
              showAlignmentButtons: false,
              showLeftAlignment: false,
              showCenterAlignment: false,
              showRightAlignment: false,
              showJustifyAlignment: false,
              showHeaderStyle: false,
              showListNumbers: false,
              showListBullets: false,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showLink: false,
              showUndo: false,
              showRedo: false,
              showDirection: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              embedButtons: FlutterQuillEmbeds.toolbarButtons(
                videoButtonOptions: null,
                imageButtonOptions: QuillToolbarImageButtonOptions(
                  imageButtonConfig: QuillToolbarImageConfig(
                    onImageInsertCallback: _insertPickedImage,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: QuillEditor.basic(
              controller: widget.controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                scrollable: false,
                expands: false,
                padding: EdgeInsets.zero,
                minHeight: 56,
                embedBuilders: FlutterQuillEmbeds.editorBuilders(
                  videoEmbedConfig: null,
                  imageEmbedConfig: QuillEditorImageEmbedConfig(
                    imageProviderBuilder: cachedQuillImageProvider,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
