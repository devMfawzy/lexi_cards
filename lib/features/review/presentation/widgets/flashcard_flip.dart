import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/rich_text_viewer.dart';

/// A flashcard that flips on a Y-axis to reveal its answer.
///
/// Keying an instance by the card's id (at the call site) makes Flutter
/// create a fresh State per card, so the flip resets instantly for a new
/// card instead of animating a "reverse" flip.
class FlashcardFlip extends StatefulWidget {
  final String front;
  final String back;
  final bool showAnswer;
  final VoidCallback? onTap;

  const FlashcardFlip({
    super.key,
    required this.front,
    required this.back,
    required this.showAnswer,
    this.onTap,
  });

  @override
  State<FlashcardFlip> createState() => _FlashcardFlipState();
}

class _FlashcardFlipState extends State<FlashcardFlip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.showAnswer ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant FlashcardFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAnswer != oldWidget.showAnswer) {
      if (widget.showAnswer) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final showingFront = angle < math.pi / 2;
          final displayAngle = showingFront ? angle : angle - math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(displayAngle),
            child: _CardFace(
              text: showingFront ? widget.front : widget.back,
              isFront: showingFront,
            ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final bool isFront;

  const _CardFace({required this.text, required this.isFront});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isFront ? colorScheme.surfaceContainerHigh : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: isFront ? colorScheme.onSurface : colorScheme.onPrimaryContainer,
          ),
          child: RichTextViewer(stored: text),
        ),
      ),
    );
  }
}
