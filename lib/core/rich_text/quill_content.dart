import 'dart:convert';

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
String plainTextPreview(String raw) =>
    documentFromStored(raw).toPlainText().replaceAll(RegExp(r'\s+'), ' ').trim();

bool isContentBlank(String raw) => plainTextPreview(raw).isEmpty;
