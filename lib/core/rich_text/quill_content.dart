import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image/image.dart' as img;

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
/// text but the content isn't actually blank (e.g. an image-only card) — the
/// caller-supplied [imagePlaceholder] so the row doesn't render as an
/// empty/broken line. Takes the placeholder as a parameter rather than
/// hardcoding it since this file is deliberately Flutter-widget-free (no
/// `BuildContext`, so it can't call `AppLocalizations.of(context)` itself).
String cardPreviewLabel(String raw, {required String imagePlaceholder}) {
  final text = plainTextPreview(raw);
  if (text.isNotEmpty) return text;
  return isContentBlank(raw) ? '' : imagePlaceholder;
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

/// Longest-side cap for an embedded image. Cards are viewed on a phone
/// screen, so there's no reason to keep a multi-megapixel camera photo
/// around — this alone is usually what shrinks a multi-MB original down to a
/// few hundred KB before it's ever base64-inlined into the Hive box.
const _maxImageDimension = 1600;
const _jpegQuality = 82;

/// Decodes, resizes, and re-encodes a picked image. Runs off the UI thread
/// via [compute] — decode/resize/encode on a full-resolution camera photo is
/// real CPU work that would otherwise jank the image-picker flow.
///
/// Takes and returns a (bytes, mimeType) pair rather than a plain
/// [Uint8List] because compression can change the format (a re-encoded
/// opaque PNG becomes a smaller JPEG), so the mime type has to travel with
/// the bytes it actually describes.
(Uint8List, String) _resizeAndCompress((Uint8List, String) original) {
  final (bytes, mimeType) = original;
  try {
    final decoded = img.decodeImage(bytes);
    // Unrecognized/undecodable format (e.g. HEIC — the `image` package
    // doesn't decode it) — embed the original bytes unchanged rather than fail.
    if (decoded == null) return original;

    final longestSide = decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longestSide > _maxImageDimension
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? _maxImageDimension : null,
            height: decoded.height > decoded.width ? _maxImageDimension : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    // Keep transparency (PNG) if the source has any; otherwise JPEG
    // compresses a photo far smaller than PNG ever would.
    final hasAlpha = resized.hasAlpha;
    final encoded = hasAlpha
        ? img.encodePng(resized)
        : img.encodeJpg(resized, quality: _jpegQuality);

    // Re-encoding isn't guaranteed to win against an already-small/optimized
    // original (e.g. a small icon-sized PNG) — only use it if it actually did.
    if (encoded.length >= bytes.length) return original;
    return (encoded, hasAlpha ? 'image/png' : 'image/jpeg');
  } catch (_) {
    // A malformed/truncated/unsupported input can throw partway through
    // decoding rather than returning null — embed the original unchanged
    // rather than lose the picked image entirely.
    return original;
  }
}

/// Converts a picked image's source into what gets embedded in the Delta.
/// A remote link (the toolbar's "Link" option) is inserted as-is; a local
/// file (gallery/camera) is resized/compressed and inlined as a base64 data
/// URI.
Future<String> imageEmbedSourceFor(String pickedPathOrUrl) async {
  if (pickedPathOrUrl.startsWith('http://') || pickedPathOrUrl.startsWith('https://')) {
    return pickedPathOrUrl;
  }
  final originalBytes = await File(pickedPathOrUrl).readAsBytes();
  final (bytes, mimeType) = await compute(
    _resizeAndCompress,
    (originalBytes, mimeTypeForPath(pickedPathOrUrl)),
  );
  return dataUriFromBytes(bytes, mimeType: mimeType);
}
