import '../entities/term_set.dart';
import '../repositories/term_repository.dart';

class GetSets {
  final TermRepository repository;
  GetSets(this.repository);

  Future<List<TermSet>> call() => repository.getSets();
}
