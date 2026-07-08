import '../entities/flashcard.dart';
import '../repositories/card_repository.dart';

class AddCard {
  final CardRepository repository;
  AddCard(this.repository);

  Future<Flashcard> call(String deckId, String front, String back) =>
      repository.addCard(deckId, front, back);
}
