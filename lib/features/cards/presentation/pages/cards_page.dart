import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/flashcard.dart';
import '../bloc/cards_cubit.dart';
import '../bloc/cards_state.dart';
import '../widgets/card_editor_dialog.dart';
import '../widgets/card_list_tile.dart';

class CardsPage extends StatelessWidget {
  final String deckId;

  const CardsPage({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CardsCubit(
        deckId: deckId,
        getCards: getIt(),
        addCardUseCase: getIt(),
        deleteCardUseCase: getIt(),
        updateCardUseCase: getIt(),
      )..loadCards(),
      child: _CardsView(deckId: deckId),
    );
  }
}

class _CardsView extends StatelessWidget {
  final String deckId;

  const _CardsView({required this.deckId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cardsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: l10n.study,
            onPressed: () async {
              // Reviewing changes each card's state and due date, both of
              // which this list shows.
              final cubit = context.read<CardsCubit>();
              await context.push('/decks/$deckId/review');
              await cubit.loadCards();
            },
          ),
        ],
      ),
      body: BlocConsumer<CardsCubit, CardsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.cards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.cards.isEmpty) {
            return EmptyState(icon: Icons.note_add_outlined, message: l10n.noCardsYet);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: state.cards.length,
            itemBuilder: (context, index) {
              final card = state.cards[index];
              return CardListTile(
                card: card,
                onDelete: () => context.read<CardsCubit>().deleteCard(card.id),
                onTap: () => _editCard(context, card),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cubit = context.read<CardsCubit>();
          final result = await showDialog<(String, String)>(
            context: context,
            builder: (_) => const CardEditorDialog(),
          );
          if (result != null) {
            unawaited(cubit.addCard(result.$1, result.$2));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editCard(BuildContext context, Flashcard card) async {
    final cubit = context.read<CardsCubit>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => CardEditorDialog(initialFront: card.front, initialBack: card.back),
    );
    if (result != null) {
      unawaited(cubit.updateCard(card, result.$1, result.$2));
    }
  }
}
