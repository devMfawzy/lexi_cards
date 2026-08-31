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
      const raw =
          '[{"insert":"Hello ","attributes":{"bold":true}},{"insert":"world\\n"}]';
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
      const raw =
          '[{"insert":"Hello ","attributes":{"bold":true}},{"insert":"world\\n"}]';
      expect(plainTextPreview(raw), 'Hello world');
    });

    test('passes legacy plain text through unchanged (trimmed)', () {
      expect(plainTextPreview('Hello world'), 'Hello world');
    });

    test('collapses multi-line content onto one line instead of cutting at the first break', () {
      const raw =
          '[{"insert":"inadequaty\\nA\\nB\\nC\\n"}]';
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
      expect(
        cardPreviewLabel('Hello world', imagePlaceholder: '📷 Image'),
        'Hello world',
      );
    });

    test('falls back to the caller-supplied placeholder for an image-only card', () {
      const raw = '[{"insert":{"image":"data:image/png;base64,AAAA"}},{"insert":"\\n"}]';
      expect(
        cardPreviewLabel(raw, imagePlaceholder: '📷 Image'),
        '📷 Image',
      );
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
      // Noisy per-pixel content rather than a flat fill — a solid color
      // compresses so well as PNG that a downscaled/recompressed JPEG can't
      // beat it, which isn't representative of an actual photo.
      final original = img.Image(width: 2000, height: 1000); // 2:1, no alpha
      final random = Random(42);
      for (var y = 0; y < original.height; y++) {
        for (var x = 0; x < original.width; x++) {
          original.setPixelRgb(x, y, random.nextInt(256), random.nextInt(256), random.nextInt(256));
        }
      }
      final file = await File(
        '${Directory.systemTemp.path}/quill_content_test_${DateTime.now().microsecondsSinceEpoch}.png',
      ).writeAsBytes(img.encodePng(original));

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
