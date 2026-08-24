import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/rating.dart';

class RatingButtons extends StatelessWidget {
  final Map<Rating, Duration> previews;
  final ValueChanged<Rating> onRate;

  const RatingButtons({
    super.key,
    required this.previews,
    required this.onRate,
  });

  static const _labels = {
    Rating.again: 'Again',
    Rating.hard: 'Hard',
    Rating.good: 'Good',
    Rating.easy: 'Easy',
  };

  static const _colors = {
    Rating.again: RatingColors.again,
    Rating.hard: RatingColors.hard,
    Rating.good: RatingColors.good,
    Rating.easy: RatingColors.easy,
  };

  String _format(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes.clamp(1, 59)}m';
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(_labels[rating]!, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (preview != null)
                    Text(
                      _format(preview),
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
