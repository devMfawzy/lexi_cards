import 'package:flutter/material.dart';
import '../../domain/entities/review_stats.dart';

class MiniBarChart extends StatelessWidget {
  final String title;
  final List<DailyCount> data;
  final Color color;

  const MiniBarChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
  });

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = data.fold<int>(0, (max, d) => d.count > max ? d.count : max);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in data)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${d.count}', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 4),
                          Container(
                            height: 56 * (d.count / safeMax).clamp(0.06, 1.0),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _weekdayLabels[d.date.weekday - 1],
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
