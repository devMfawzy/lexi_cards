import '../../../cards/domain/entities/flashcard.dart';
import '../../../cards/domain/repositories/card_repository.dart';

class GetDueCards {
  final CardRepository repository;
  GetDueCards(this.repository);

  Future<List<Flashcard>> call(String deckId) => repository.getDueCards(deckId);
}
