import 'package:flutter/material.dart';

/// Forces LTR rendering for numeric content with a tightly-adjacent symbol
/// or letter (a fraction like "0 / 1", a duration badge like "4ي") that
/// should always read digit-first. Unicode's bidi algorithm otherwise
/// reorders these once they're embedded in RTL (Arabic) text — digits and
/// neutral characters like "/" have no inherent direction of their own and
/// pick up the surrounding paragraph's, which visibly flips them (observed:
/// "0 / 1" rendered as "1 / 0" in Arabic). Plain space-separated count-plus-word
/// text doesn't need this — a space is enough of a break for the number to
/// keep its own position.
class LtrText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LtrText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    // Fix the digit order without changing where the text sits: keep
    // positioning relative to the ambient (real) direction — e.g. still
    // right-aligned when embedded in an RTL layout that stretches this
    // widget to full width — and only override direction for bidi
    // resolution of the string's own characters.
    final ambientIsRtl = Directionality.of(context) == TextDirection.rtl;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(text, style: style, textAlign: ambientIsRtl ? TextAlign.right : TextAlign.left),
    );
  }
}
