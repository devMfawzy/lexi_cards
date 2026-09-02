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

String deltaJsonFromDocument(Document document) => jsonEncode(document.toDelta().toJson());

/// A single-line summary of the stored content, for list previews. Quill's
/// plain text keeps line breaks (each paragraph ends in `\n`), which would
/// make a `Text(..., maxLines: 1)` cut off at the *first* line instead of
/// truncating the whole thing — so runs of whitespace collapse to one space.
/// Embeds (images, ...) come through as the U+FFFC object-replacement
/// character, which reads as a mangled glyph rather than actual text, so
/// it's stripped here too — [cardPreviewLabel] is what shows something for
/// an embed-only face.
String plainTextPreview(String raw) => documentFromStored(
  raw,
).toPlainText().replaceAll('￼', '').replaceAll(RegExp(r'\s+'), ' ').trim();

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

/// Thrown when a picked image can't be brought under [_maxEmbeddedBytes].
/// Surfaced to the user rather than silently inlining something enormous.
class ImageTooLargeException implements Exception {
  const ImageTooLargeException();
}

/// Longest-side cap for an embedded image. Cards are viewed on a phone
/// screen, so there's no reason to keep a multi-megapixel camera photo
/// around — this alone is usually what shrinks a multi-MB original down to a
/// few hundred KB before it's ever base64-inlined into the Hive box.
const _maxImageDimension = 1600;
const _jpegQuality = 82;

/// Hard ceiling on a single embedded image's encoded bytes, before base64
/// (which adds a further ~33%). Images live *inline* in the card record, so an
/// uncapped image means an uncapped card — and every card is carried whole in
/// the sync payload. [_dimensionLadder] is walked until the result fits.
const _maxEmbeddedBytes = 900 * 1024;
const _dimensionLadder = [_maxImageDimension, 1200, 900, 640];

/// Decodes, resizes, and re-encodes a picked image so it fits within
/// [_maxEmbeddedBytes], returning null when that isn't achievable. Runs off
/// the UI thread via [compute] — decode/resize/encode on a full-resolution
/// camera photo is real CPU work that would otherwise jank the picker flow.
///
/// Takes and returns a (bytes, mimeType) pair rather than a plain
/// [Uint8List] because compression can change the format (a re-encoded
/// opaque PNG becomes a smaller JPEG), so the mime type has to travel with
/// the bytes it actually describes.
(Uint8List, String)? _resizeAndCompress((Uint8List, String) original) {
  final (bytes, _) = original;
  try {
    final decoded = img.decodeImage(bytes);
    // Undecodable format. Note this is an *Android* path, not the iOS one the
    // obvious guess suggests: iOS's image_picker sniffs the leading byte and
    // re-encodes anything it doesn't recognise (HEIC included) to JPEG before
    // we ever see it, whereas Android hands back the picked file untouched
    // unless a quality/size limit was requested. We can't shrink what we
    // can't decode, so it's only safe if it already fits.
    if (decoded == null) return _originalIfSmallEnough(original);

    for (final maxSide in _dimensionLadder) {
      final resized = _resizedToFit(decoded, maxSide);
      // Keep transparency (PNG) if the source has any; otherwise JPEG
      // compresses a photo far smaller than PNG ever would.
      final candidate = resized.hasAlpha
          ? (img.encodePng(resized), 'image/png')
          : (img.encodeJpg(resized, quality: _jpegQuality), 'image/jpeg');
      if (candidate.$1.length > _maxEmbeddedBytes) continue;
      // Re-encoding isn't guaranteed to win against an already-small,
      // already-optimized original (e.g. an icon-sized PNG). Safe to return
      // it here: it's no larger than a candidate already under the cap.
      if (candidate.$1.length >= bytes.length) return original;
      return candidate;
    }

    // Still over the cap at the smallest size, which means transparency is
    // what's holding it there — PNG can't compress a photograph. Flatten and
    // let JPEG do what PNG can't.
    final flattened = _flattenOntoWhite(_resizedToFit(decoded, _dimensionLadder.last));
    final jpg = img.encodeJpg(flattened, quality: _jpegQuality);
    return jpg.length <= _maxEmbeddedBytes ? (jpg, 'image/jpeg') : null;
  } catch (_) {
    // A malformed/truncated input can throw partway through decoding rather
    // than returning null.
    return _originalIfSmallEnough(original);
  }
}

(Uint8List, String)? _originalIfSmallEnough((Uint8List, String) original) =>
    original.$1.length <= _maxEmbeddedBytes ? original : null;

img.Image _resizedToFit(img.Image source, int maxSide) {
  final longest = source.width > source.height ? source.width : source.height;
  if (longest <= maxSide) return source;
  return img.copyResize(
    source,
    width: source.width >= source.height ? maxSide : null,
    height: source.height > source.width ? maxSide : null,
    interpolation: img.Interpolation.average,
  );
}

/// JPEG has no alpha channel, so transparent pixels would encode as whatever
/// happens to sit in their RGB channels — commonly black. Compositing onto
/// white first keeps the result looking like what the user actually picked.
img.Image _flattenOntoWhite(img.Image source) {
  final canvas = img.Image(width: source.width, height: source.height, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  return img.compositeImage(canvas, source);
}

/// Converts a picked image's source into what gets embedded in the Delta.
/// A remote link (the toolbar's "Link" option) is inserted as-is; a local
/// file (gallery/camera) is resized/compressed and inlined as a base64 data
/// URI. Throws [ImageTooLargeException] if the image can't be brought under
/// the embed size cap.
Future<String> imageEmbedSourceFor(String pickedPathOrUrl) async {
  if (pickedPathOrUrl.startsWith('http://') || pickedPathOrUrl.startsWith('https://')) {
    return pickedPathOrUrl;
  }
  final originalBytes = await File(pickedPathOrUrl).readAsBytes();
  final result = await compute(_resizeAndCompress, (
    originalBytes,
    mimeTypeForPath(pickedPathOrUrl),
  ));
  if (result == null) throw const ImageTooLargeException();
  final (bytes, mimeType) = result;
  return dataUriFromBytes(bytes, mimeType: mimeType);
}
