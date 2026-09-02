// Generates the app icon source image, so the asset is reproducible rather
// than a binary nobody can regenerate.
//
//   dart run tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// A stack of three cards, back-to-front, in the app's own palette. Drawn at
// 4x and downsampled, since fillRect's rounded corners are hard-edged.

import 'dart:io';

import 'package:image/image.dart' as img;

const _size = 1024;
const _scale = 4;

// Matches lib/core/theme/app_theme.dart.
final _ground = img.ColorRgb8(0x0F, 0x6B, 0x5C);
final _backCard = img.ColorRgb8(0x35, 0x8F, 0x7E);
final _midCard = img.ColorRgb8(0x7A, 0xD8, 0xC4);
final _frontCard = img.ColorRgb8(0xF5, 0xFB, 0xF9);
final _accent = img.ColorRgb8(0x0F, 0x6B, 0x5C);

void main() {
  Directory('assets/icon').createSync(recursive: true);
  _write('assets/icon/app_icon.png', _draw(withBackground: true, inset: 1.0));
  // Android's adaptive icon crops the foreground to a shape of its choosing
  // and animates it, so the artwork has to sit well inside the safe zone and
  // the background is supplied separately as a flat colour.
  _write(
    'assets/icon/app_icon_foreground.png',
    _draw(withBackground: false, inset: 0.62),
  );
}

void _write(String path, img.Image icon) {
  File(path).writeAsBytesSync(img.encodePng(icon));
  stdout.writeln('wrote $path (${icon.width}x${icon.height})');
}

img.Image _draw({required bool withBackground, required double inset}) {
  const s = _size * _scale;
  final canvas = img.Image(width: s, height: s, numChannels: 4);
  if (withBackground) {
    img.fill(canvas, color: _ground);
  }

  // Three cards fanned left-to-right, each offset on both axes so the stack
  // still reads as a stack once the icon is 40px wide. Everything stays inside
  // ~72% of the canvas, clear of the rounded mask iOS applies.
  // Positions are expressed relative to the canvas centre so the whole group
  // scales together when inset for the adaptive foreground.
  double at(double v) => 0.5 + (v - 0.5) * inset;
  final w = (s * 0.36 * inset).round();

  _card(canvas, cx: (s * at(0.40)).round(), cy: (s * at(0.44)).round(), w: w, color: _backCard);
  _card(canvas, cx: (s * at(0.46)).round(), cy: (s * at(0.49)).round(), w: w, color: _midCard);
  final front = _card(
    canvas,
    cx: (s * at(0.545)).round(),
    cy: (s * at(0.55)).round(),
    w: w,
    color: _frontCard,
  );

  // Two text-lines on the front card: enough to say "flashcard" without a
  // glyph that would disappear at small sizes.
  final lineHeight = (s * 0.026 * inset).round();
  final lineRadius = lineHeight / 2;
  _line(canvas, front, widthFactor: 0.56, dy: -lineHeight * 2, h: lineHeight, r: lineRadius);
  _line(canvas, front, widthFactor: 0.34, dy: lineHeight, h: lineHeight, r: lineRadius);

  return img.copyResize(
    canvas,
    width: _size,
    height: _size,
    interpolation: img.Interpolation.average,
  );
}

/// Draws a centred card and returns its bounds as [left, top, right, bottom].
List<int> _card(
  img.Image canvas, {
  required int cx,
  required int cy,
  required int w,
  required img.Color color,
}) {
  final h = (w * 1.32).round();
  final bounds = [cx - w ~/ 2, cy - h ~/ 2, cx + w ~/ 2, cy + h ~/ 2];
  img.fillRect(
    canvas,
    x1: bounds[0],
    y1: bounds[1],
    x2: bounds[2],
    y2: bounds[3],
    color: color,
    radius: w * 0.12,
  );
  return bounds;
}

void _line(
  img.Image canvas,
  List<int> card, {
  required double widthFactor,
  required int dy,
  required int h,
  required num r,
}) {
  final cardWidth = card[2] - card[0];
  final cx = (card[0] + card[2]) ~/ 2;
  final cy = (card[1] + card[3]) ~/ 2 + dy;
  final w = (cardWidth * widthFactor).round();
  img.fillRect(
    canvas,
    x1: cx - w ~/ 2,
    y1: cy - h ~/ 2,
    x2: cx + w ~/ 2,
    y2: cy + h ~/ 2,
    color: _accent,
    radius: r,
  );
}
