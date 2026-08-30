import '../entities/deck.dart';
import '../repositories/card_repository.dart';

class RenameDeck {
  final CardRepository repository;
  RenameDeck(this.repository);

  Future<Deck> call(String id, String name) => repository.renameDeck(id, name);
}
