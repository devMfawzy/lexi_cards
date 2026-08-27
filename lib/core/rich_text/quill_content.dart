import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';

/// Cards store front/back as Quill Delta JSON. These helpers convert between
/// that stored string and a [Document], falling back to treating the raw
/// string as plain text for cards created before rich text existed (or any
/// other malformed content) — the fallback never throws.
Document documentFromStored(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return Document.fromJson(decoded);
    }
  } catch (_) {
    // Not valid JSON, or not a valid Delta — treat as legacy plain text.
  }
  return _plainTextDocument(raw);
}

Document _plainTextDocument(String raw) {
  final document = Document();
  if (raw.isNotEmpty) {
    document.insert(0, raw);
  }
  return document;
}

String deltaJsonFromDocument(Document document) =>
    jsonEncode(document.toDelta().toJson());

/// A single-line summary of the stored content, for list previews. Quill's
/// plain text keeps line breaks (each paragraph ends in `\n`), which would
/// make a `Text(..., maxLines: 1)` cut off at the *first* line instead of
/// truncating the whole thing — so runs of whitespace collapse to one space.
/// Embeds (images, ...) come through as the U+FFFC object-replacement
/// character, which reads as a mangled glyph rather than actual text, so
/// it's stripped here too — [cardPreviewLabel] is what shows something for
/// an embed-only face.
String plainTextPreview(String raw) => documentFromStored(raw)
    .toPlainText()
    .replaceAll('￼', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Delta JSON `insert` ops are either a [String] (text) or a [Map] (an
/// embed — image, video, ...). [Document.toPlainText] only covers text, so
/// an image-only card would otherwise read as blank and get silently
/// rejected by the editor's save button.
bool isContentBlank(String raw) {
  if (plainTextPreview(raw).isNotEmpty) return false;
  return !documentFromStored(raw).toDelta().toList().any((op) => op.data is Map);
}

/// List-preview label for a card face: the plain text, or — when there's no
/// text but the content isn't actually blank (e.g. an image-only card) — a
/// placeholder so the row doesn't render as an empty/broken line.
String cardPreviewLabel(String raw) {
  final text = plainTextPreview(raw);
  if (text.isNotEmpty) return text;
  return isContentBlank(raw) ? '' : '📷 Image';
}

String mimeTypeForPath(String path) {
  switch (path.toLowerCase().split('.').last) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

String dataUriFromBytes(Uint8List bytes, {required String mimeType}) =>
    'data:$mimeType;base64,${base64Encode(bytes)}';

/// Converts a picked image's source into what gets embedded in the Delta.
/// A remote link (the toolbar's "Link" option) is inserted as-is; a local
/// file (gallery/camera) is read and inlined as a base64 data URI.
Future<String> imageEmbedSourceFor(String pickedPathOrUrl) async {
  if (pickedPathOrUrl.startsWith('http://') || pickedPathOrUrl.startsWith('https://')) {
    return pickedPathOrUrl;
  }
  final bytes = await File(pickedPathOrUrl).readAsBytes();
  return dataUriFromBytes(bytes, mimeType: mimeTypeForPath(pickedPathOrUrl));
}
