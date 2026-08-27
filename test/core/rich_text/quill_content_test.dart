import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
  });
}
