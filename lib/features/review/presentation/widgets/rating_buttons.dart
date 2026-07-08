import 'package:flutter/material.dart';
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
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => onRate(rating),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_labels[rating]!),
                  if (preview != null)
                    Text(
                      _format(preview),
                      style: Theme.of(context).textTheme.bodySmall,
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
