import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/decks_cubit.dart';
import '../bloc/decks_state.dart';
import '../widgets/deck_list_tile.dart';
import '../widgets/deck_name_dialog.dart';

class DecksPage extends StatelessWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DecksCubit(
        getDecks: getIt(),
        createDeckUseCase: getIt(),
        renameDeckUseCase: getIt(),
        deleteDeckUseCase: getIt(),
        getCards: getIt(),
      )..loadDecks(),
      child: const _DecksView(),
    );
  }
}

class _DecksView extends StatelessWidget {
  const _DecksView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDecksTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.statsTooltip,
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocConsumer<DecksCubit, DecksState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.summaries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.summaries.isEmpty) {
            return EmptyState(
              icon: Icons.style_outlined,
              message: l10n.noDecksYet,
            );
          }
          final totalDue = state.summaries.fold<int>(0, (sum, s) => sum + s.dueCount);
          return RefreshIndicator(
            onRefresh: () => context.read<DecksCubit>().loadDecks(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.summaries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _StudyAllHeader(
                    dueCount: totalDue,
                    onTap: () => context.push('/study'),
                  );
                }
                final summary = state.summaries[index - 1];
                return DeckListTile(
                  summary: summary,
                  onTap: () => context.push('/decks/${summary.deck.id}'),
                  onStudy: () => context.push('/decks/${summary.deck.id}/review'),
                  onRename: (name) => context.read<DecksCubit>().renameDeck(summary.deck.id, name),
                  onDelete: () => context.read<DecksCubit>().deleteDeck(summary.deck.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cubit = context.read<DecksCubit>();
          final name = await showDialog<String>(
            context: context,
            builder: (_) => const DeckNameDialog(),
          );
          if (name != null) {
            cubit.createDeck(name);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StudyAllHeader extends StatelessWidget {
  final int dueCount;
  final VoidCallback onTap;

  const _StudyAllHeader({required this.dueCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: colorScheme.primaryContainer,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.studyAllDecksHeader,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dueCount(dueCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.play_circle_fill, color: colorScheme.onPrimaryContainer, size: 36),
                  tooltip: l10n.studyAllDecksHeader,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
