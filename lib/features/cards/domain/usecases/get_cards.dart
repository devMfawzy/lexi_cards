import '../entities/flashcard.dart';
import '../repositories/card_repository.dart';

class GetCards {
  final CardRepository repository;
  GetCards(this.repository);

  Future<List<Flashcard>> call(String deckId) => repository.getCards(deckId);
}
