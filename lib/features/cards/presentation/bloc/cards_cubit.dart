import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/add_card.dart';
import '../../domain/usecases/delete_card.dart';
import '../../domain/usecases/get_cards.dart';
import '../../domain/usecases/update_card.dart';
import 'cards_state.dart';

class CardsCubit extends Cubit<CardsState> {
  final String deckId;
  final GetCards getCards;
  final AddCard addCardUseCase;
  final DeleteCard deleteCardUseCase;
  final UpdateCard updateCardUseCase;

  CardsCubit({
    required this.deckId,
    required this.getCards,
    required this.addCardUseCase,
    required this.deleteCardUseCase,
    required this.updateCardUseCase,
  }) : super(const CardsState());

  Future<void> loadCards() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final cards = await getCards(deckId);
      emit(state.copyWith(cards: cards, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> addCard(String front, String back) async {
    try {
      await addCardUseCase(deckId, front, back);
      await loadCards();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> deleteCard(String id) async {
    try {
      await deleteCardUseCase(id);
      await loadCards();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> updateCard(Flashcard existing, String front, String back) async {
    try {
      await updateCardUseCase(existing.copyWith(front: front, back: back));
      await loadCards();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
