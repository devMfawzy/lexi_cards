import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/cards_cubit.dart';
import '../bloc/cards_state.dart';
import '../widgets/add_card_dialog.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Study',
            onPressed: () => context.push('/decks/$deckId/review'),
          ),
        ],
      ),
      body: BlocConsumer<CardsCubit, CardsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.cards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.cards.isEmpty) {
            return const Center(child: Text('No cards yet. Add one below.'));
          }
          return ListView.builder(
            itemCount: state.cards.length,
            itemBuilder: (context, index) {
              final card = state.cards[index];
              return CardListTile(
                card: card,
                onDelete: () => context.read<CardsCubit>().deleteCard(card.id),
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
            builder: (_) => const AddCardDialog(),
          );
          if (result != null) {
            cubit.addCard(result.$1, result.$2);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
