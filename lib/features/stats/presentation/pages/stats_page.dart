import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../bloc/stats_cubit.dart';
import '../bloc/stats_state.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/stat_tile.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatsCubit(getReviewStats: getIt())..load(),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: BlocConsumer<StatsCubit, StatsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = state.stats;
          if (stats == null || stats.totalCards == 0) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              message: 'No stats yet. Add some cards and start reviewing.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<StatsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatTile(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Day streak',
                      value: '${stats.currentStreakDays}',
                    ),
                    StatTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Longest streak',
                      value: '${stats.longestStreakDays}',
                    ),
                    StatTile(
                      icon: Icons.check_circle_outline,
                      label: 'Retention',
                      value: '${(stats.retentionRate * 100).round()}%',
                    ),
                    StatTile(
                      icon: Icons.style_outlined,
                      label: 'Cards learned',
                      value: '${stats.cardsInProgress}/${stats.totalCards}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MiniBarChart(
                  title: 'Reviews — last 7 days',
                  data: stats.reviewsLast7Days,
                  color: RatingColors.good,
                ),
                const SizedBox(height: 16),
                MiniBarChart(
                  title: 'Due — next 7 days',
                  data: stats.dueNext7Days,
                  color: CardStateColors.newCard,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
