import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../sync/presentation/bloc/sync_cubit.dart';
import '../../../sync/presentation/bloc/sync_state.dart';
import '../bloc/stats_cubit.dart';
import '../bloc/stats_state.dart';
import '../widgets/mini_bar_chart.dart';
import '../widgets/stat_tile.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StatsCubit(getReviewStats: getIt())..load()),
        BlocProvider.value(value: getIt<SyncCubit>()),
      ],
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: BlocListener<SyncCubit, SyncState>(
        // A sync brings in reviews done on another device, which changes every
        // number on this screen.
        listenWhen: (before, after) => before.dataVersion != after.dataVersion,
        listener: (context, _) => unawaited(context.read<StatsCubit>().load()),
        child: BlocConsumer<StatsCubit, StatsState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.stats == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final stats = state.stats;
            if (stats == null || stats.totalCards == 0) {
              return EmptyState(icon: Icons.insights_outlined, message: l10n.noStatsYet);
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
                        label: l10n.dayStreak,
                        value: '${stats.currentStreakDays}',
                      ),
                      StatTile(
                        icon: Icons.emoji_events_outlined,
                        label: l10n.longestStreak,
                        value: '${stats.longestStreakDays}',
                      ),
                      StatTile(
                        icon: Icons.check_circle_outline,
                        label: l10n.retention,
                        value: '${(stats.retentionRate * 100).round()}%',
                      ),
                      StatTile(
                        icon: Icons.style_outlined,
                        label: l10n.cardsLearned,
                        value: '${stats.cardsInProgress}/${stats.totalCards}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MiniBarChart(
                    title: l10n.reviewsLast7Days,
                    data: stats.reviewsLast7Days,
                    color: RatingColors.good,
                  ),
                  const SizedBox(height: 16),
                  MiniBarChart(
                    title: l10n.dueNext7Days,
                    data: stats.dueNext7Days,
                    color: CardStateColors.newCard,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
