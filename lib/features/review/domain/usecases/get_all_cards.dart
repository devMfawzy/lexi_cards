import '../../../cards/domain/entities/flashcard.dart';
import '../../../cards/domain/repositories/card_repository.dart';

class GetAllCards {
  final CardRepository repository;
  GetAllCards(this.repository);

  Future<List<Flashcard>> call() => repository.getAllCards();
}
