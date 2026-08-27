import '../entities/flashcard.dart';
import '../repositories/card_repository.dart';

class UpdateCard {
  final CardRepository repository;
  UpdateCard(this.repository);

  Future<void> call(Flashcard card) => repository.updateCard(card);
}
