import '../entities/deck.dart';
import '../repositories/card_repository.dart';

class GetDecks {
  final CardRepository repository;
  GetDecks(this.repository);

  Future<List<Deck>> call() => repository.getDecks();
}
