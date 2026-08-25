import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/empty_state.dart';
import '../bloc/decks_cubit.dart';
import '../bloc/decks_state.dart';
import '../widgets/create_deck_dialog.dart';
import '../widgets/deck_list_tile.dart';

class DecksPage extends StatelessWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DecksCubit(
        getDecks: getIt(),
        createDeckUseCase: getIt(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Stats',
            onPressed: () => context.push('/stats'),
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
            return const EmptyState(
              icon: Icons.style_outlined,
              message: 'No decks yet. Tap + to create one.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<DecksCubit>().loadDecks(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.summaries.length,
              itemBuilder: (context, index) {
                final summary = state.summaries[index];
                return DeckListTile(
                  summary: summary,
                  onTap: () => context.push('/decks/${summary.deck.id}'),
                  onStudy: () => context.push('/decks/${summary.deck.id}/review'),
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
            builder: (_) => const CreateDeckDialog(),
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
