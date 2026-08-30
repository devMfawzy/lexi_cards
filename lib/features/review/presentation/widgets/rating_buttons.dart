import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ltr_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/rating.dart';

class RatingButtons extends StatelessWidget {
  final Map<Rating, Duration> previews;
  final ValueChanged<Rating> onRate;

  const RatingButtons({
    super.key,
    required this.previews,
    required this.onRate,
  });

  static const _colors = {
    Rating.again: RatingColors.again,
    Rating.hard: RatingColors.hard,
    Rating.good: RatingColors.good,
    Rating.easy: RatingColors.easy,
  };

  String _label(AppLocalizations l10n, Rating rating) {
    switch (rating) {
      case Rating.again:
        return l10n.ratingAgain;
      case Rating.hard:
        return l10n.ratingHard;
      case Rating.good:
        return l10n.ratingGood;
      case Rating.easy:
        return l10n.ratingEasy;
    }
  }

  String _format(AppLocalizations l10n, Duration d) {
    if (d.inDays >= 1) return l10n.durationDays(d.inDays);
    if (d.inHours >= 1) return l10n.durationHours(d.inHours);
    return l10n.durationMinutes(d.inMinutes.clamp(1, 59));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: Rating.values.map((rating) {
        final preview = previews[rating];
        final color = _colors[rating]!;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => onRate(rating),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_label(l10n, rating), style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (preview != null)
                    LtrText(
                      _format(l10n, preview),
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
