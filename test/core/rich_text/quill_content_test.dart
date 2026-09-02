import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lexi_cards/core/rich_text/quill_content.dart';

void main() {
  group('documentFromStored', () {
    test('round-trips valid Delta JSON', () {
      const raw = '[{"insert":"Hello ","attributes":{"bold":true}},{"insert":"world\\n"}]';
      final document = documentFromStored(raw);
      expect(document.toPlainText(), 'Hello world\n');
    });

    test('falls back to plain text for a legacy pre-rich-text card', () {
      final document = documentFromStored('Hello world');
      expect(document.toPlainText(), 'Hello world\n');
    });

    test('falls back to plain text for malformed JSON, without throwing', () {
      expect(() => documentFromStored('not { valid json'), returnsNormally);
      final document = documentFromStored('not { valid json');
      expect(document.toPlainText(), 'not { valid json\n');
    });

    test('falls back to plain text for valid JSON that is not a Delta list', () {
      // "42" and '"hello"' are valid JSON but decode to an int/String, not a
      // List of Delta ops — must be treated as literal legacy text, not
      // silently dropped or misinterpreted.
      expect(documentFromStored('42').toPlainText(), '42\n');
      expect(documentFromStored('"hello"').toPlainText(), '"hello"\n');
    });

    test('handles an empty string', () {
      expect(() => documentFromStored(''), returnsNormally);
      expect(documentFromStored('').toPlainText(), '\n');
    });
  });

  group('deltaJsonFromDocument', () {
    test('produces JSON that documentFromStored can read back', () {
      final document = documentFromStored('plain text card');
      final json = deltaJsonFromDocument(document);

      expect(() => jsonDecode(json), returnsNormally);
      expect(jsonDecode(json), isA<List>());
      expect(documentFromStored(json).toPlainText(), 'plain text card\n');
    });
  });

  group('plainTextPreview', () {
    test('strips formatting and trailing newline from rich content', () {
      const raw = '[{"insert":"Hello ","attributes":{"bold":true}},{"insert":"world\\n"}]';
      expect(plainTextPreview(raw), 'Hello world');
    });

    test('passes legacy plain text through unchanged (trimmed)', () {
      expect(plainTextPreview('Hello world'), 'Hello world');
    });

    test('collapses multi-line content onto one line instead of cutting at the first break', () {
      const raw = '[{"insert":"inadequaty\\nA\\nB\\nC\\n"}]';
      expect(plainTextPreview(raw), 'inadequaty A B C');
    });
  });

  group('isContentBlank', () {
    test('is true for an empty document', () {
      final document = documentFromStored('');
      expect(isContentBlank(deltaJsonFromDocument(document)), isTrue);
    });

    test('is true for whitespace-only legacy text', () {
      expect(isContentBlank('   '), isTrue);
    });

    test('is false once there is real content', () {
      expect(isContentBlank('Hello'), isFalse);
    });

    test('is false for an image-only card with no text at all', () {
      const raw = '[{"insert":{"image":"data:image/png;base64,AAAA"}},{"insert":"\\n"}]';
      expect(isContentBlank(raw), isFalse);
    });
  });

  group('cardPreviewLabel', () {
    test('behaves like plainTextPreview when there is text', () {
      expect(cardPreviewLabel('Hello world', imagePlaceholder: '📷 Image'), 'Hello world');
    });

    test('falls back to the caller-supplied placeholder for an image-only card', () {
      const raw = '[{"insert":{"image":"data:image/png;base64,AAAA"}},{"insert":"\\n"}]';
      expect(cardPreviewLabel(raw, imagePlaceholder: '📷 Image'), '📷 Image');
    });

    test('is empty for a genuinely blank card', () {
      expect(cardPreviewLabel('', imagePlaceholder: '📷 Image'), isEmpty);
    });
  });

  group('mimeTypeForPath', () {
    test('maps common image extensions', () {
      expect(mimeTypeForPath('photo.png'), 'image/png');
      expect(mimeTypeForPath('photo.PNG'), 'image/png');
      expect(mimeTypeForPath('photo.jpg'), 'image/jpeg');
      expect(mimeTypeForPath('photo.jpeg'), 'image/jpeg');
      expect(mimeTypeForPath('photo.gif'), 'image/gif');
      expect(mimeTypeForPath('photo.webp'), 'image/webp');
      expect(mimeTypeForPath('photo.heic'), 'image/heic');
    });

    test('defaults to jpeg for an unrecognized extension', () {
      expect(mimeTypeForPath('photo.bmp'), 'image/jpeg');
    });
  });

  group('dataUriFromBytes', () {
    test('round-trips arbitrary bytes back out through base64', () {
      final bytes = Uint8List.fromList([0, 1, 2, 255, 128, 64]);
      final uri = dataUriFromBytes(bytes, mimeType: 'image/png');

      expect(uri, startsWith('data:image/png;base64,'));
      final decoded = base64Decode(uri.split(',').last);
      expect(decoded, bytes);
    });
  });

  group('imageEmbedSourceFor', () {
    test('passes an http(s) link through unchanged', () async {
      const url = 'https://example.com/cat.jpg';
      expect(await imageEmbedSourceFor(url), url);
    });

    test('reads a local file and inlines it as a base64 data URI', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final file = await File(
        '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}.png',
      ).writeAsBytes(bytes);

      try {
        final source = await imageEmbedSourceFor(file.path);
        expect(source, startsWith('data:image/png;base64,'));
        expect(base64Decode(source.split(',').last), bytes);
      } finally {
        await file.delete();
      }
    });

    test('downsizes an oversized opaque image and re-encodes it as jpeg', () async {
      final file = await _writePng(_photoLike(width: 2000, height: 1000));

      try {
        final source = await imageEmbedSourceFor(file.path);
        expect(source, startsWith('data:image/jpeg;base64,'));

        final decodedBytes = base64Decode(source.split(',').last);
        expect(decodedBytes.length, lessThan(await file.length()));

        final resized = img.decodeImage(decodedBytes)!;
        expect(resized.width, 1600);
        expect(resized.height, 800); // aspect ratio preserved
      } finally {
        await file.delete();
      }
    });

    test('steps down to a smaller size when 1600px would exceed the size cap', () async {
      // Per-pixel random noise is incompressible, so a 1600px encode blows the
      // cap and the dimension ladder has to keep going. A real photo never
      // looks like this, which is exactly why it's the useful stress case.
      final file = await _writePng(_noise(width: 2400, height: 1200));

      try {
        final source = await imageEmbedSourceFor(file.path);
        final decodedBytes = base64Decode(source.split(',').last);

        expect(decodedBytes.length, lessThanOrEqualTo(900 * 1024));
        final resized = img.decodeImage(decodedBytes)!;
        expect(resized.width, lessThan(1600));
        expect(resized.width * 1.0 / resized.height, closeTo(2.0, 0.01));
      } finally {
        await file.delete();
      }
    });

    test('flattens transparency onto white when png cannot get under the cap', () async {
      // Noise *and* an alpha channel, square so that even the smallest rung
      // still has too many pixels: PNG can't compress it at any size, so the
      // only way under the cap is to drop alpha and let JPEG handle it.
      final file = await _writePng(_noise(width: 2400, height: 2400, withAlpha: true));

      try {
        final source = await imageEmbedSourceFor(file.path);
        expect(source, startsWith('data:image/jpeg;base64,'));

        final decodedBytes = base64Decode(source.split(',').last);
        expect(decodedBytes.length, lessThanOrEqualTo(900 * 1024));
        expect(img.decodeImage(decodedBytes)!.hasAlpha, isFalse);
      } finally {
        await file.delete();
      }
    });

    test('refuses an undecodable file that is already over the cap', () async {
      // Can't decode it, so can't shrink it — inlining it whole would bloat
      // the card record itself, so the pick is rejected instead.
      final file = await File(
        '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}.heic',
      ).writeAsBytes(Uint8List(2 * 1024 * 1024));

      try {
        expect(() => imageEmbedSourceFor(file.path), throwsA(isA<ImageTooLargeException>()));
      } finally {
        await file.delete();
      }
    });

    test('embeds an undecodable file unchanged when it is small enough', () async {
      final bytes = Uint8List.fromList(List.filled(1024, 7));
      final file = await File(
        '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}.heic',
      ).writeAsBytes(bytes);

      try {
        final source = await imageEmbedSourceFor(file.path);
        expect(base64Decode(source.split(',').last), bytes);
      } finally {
        await file.delete();
      }
    });

    test('downsizes an oversized transparent image but keeps it as png', () async {
      final original = img.Image(width: 3000, height: 1500, numChannels: 4);
      final file = await File(
        '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}.png',
      ).writeAsBytes(img.encodePng(original));

      try {
        final source = await imageEmbedSourceFor(file.path);
        expect(source, startsWith('data:image/png;base64,'));

        final resized = img.decodeImage(base64Decode(source.split(',').last))!;
        expect(resized.width, 1600);
        expect(resized.height, 800);
        expect(resized.hasAlpha, isTrue);
      } finally {
        await file.delete();
      }
    });

    test('leaves an already-small image alone rather than risk making it bigger', () async {
      final original = img.Image(width: 40, height: 40);
      final originalBytes = img.encodePng(original);
      final file = await File(
        '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}.png',
      ).writeAsBytes(originalBytes);

      try {
        final source = await imageEmbedSourceFor(file.path);
        final decodedBytes = base64Decode(source.split(',').last);
        expect(decodedBytes.length, lessThanOrEqualTo(originalBytes.length));
      } finally {
        await file.delete();
      }
    });
  });
}

/// Smooth, varied content with a light dither — the dither defeats PNG's
/// row prediction (so the source file is genuinely large, like a photo) while
/// JPEG absorbs it in quantization. A flat fill would compress so well as PNG
/// that no re-encode could ever beat it, which isn't a realistic case.
img.Image _photoLike({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  final random = Random(1);
  int channel(num base) => (base + random.nextInt(13) - 6).clamp(0, 255).toInt();
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(
        x,
        y,
        channel(sin(x / 23) * 110 + 128),
        channel(sin(y / 31) * 110 + 128),
        channel(sin((x + y) / 19) * 110 + 128),
      );
    }
  }
  return image;
}

/// Per-pixel random noise — deliberately incompressible in any format, to
/// force the encoder down the dimension ladder.
img.Image _noise({required int width, required int height, bool withAlpha = false}) {
  final image = img.Image(width: width, height: height, numChannels: withAlpha ? 4 : 3);
  final random = Random(42);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final (r, g, b) = (random.nextInt(256), random.nextInt(256), random.nextInt(256));
      if (withAlpha) {
        image.setPixelRgba(x, y, r, g, b, random.nextInt(256));
      } else {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
  return image;
}

int _tmpCounter = 0;
Future<File> _writePng(img.Image image) => File(
  '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}_${_tmpCounter++}.png',
).writeAsBytes(img.encodePng(image));
