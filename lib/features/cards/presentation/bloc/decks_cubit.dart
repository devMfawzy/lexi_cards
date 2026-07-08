import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/create_deck.dart';
import '../../domain/usecases/delete_deck.dart';
import '../../domain/usecases/get_cards.dart';
import '../../domain/usecases/get_decks.dart';
import 'decks_state.dart';

class DecksCubit extends Cubit<DecksState> {
  final GetDecks getDecks;
  final CreateDeck createDeckUseCase;
  final DeleteDeck deleteDeckUseCase;
  final GetCards getCards;

  DecksCubit({
    required this.getDecks,
    required this.createDeckUseCase,
    required this.deleteDeckUseCase,
    required this.getCards,
  }) : super(const DecksState());

  Future<void> loadDecks() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final decks = await getDecks();
      final now = DateTime.now();
      final summaries = <DeckSummary>[];
      for (final deck in decks) {
        final cards = await getCards(deck.id);
        final newCount = cards.where((c) => c.state == CardState.newCard).length;
        final dueCount = cards
            .where((c) => c.state != CardState.newCard && !c.dueDate.isAfter(now))
            .length;
        summaries.add(DeckSummary(deck: deck, dueCount: dueCount, newCount: newCount));
      }
      emit(state.copyWith(summaries: summaries, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> createDeck(String name) async {
    try {
      await createDeckUseCase(name);
      await loadDecks();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> deleteDeck(String id) async {
    try {
      await deleteDeckUseCase(id);
      await loadDecks();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
