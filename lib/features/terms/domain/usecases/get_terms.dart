import '../entities/term.dart';
import '../repositories/term_repository.dart';

class GetTerms {
  final TermRepository repository;
  GetTerms(this.repository);

  Future<List<Term>> call(String setId) => repository.getTerms(setId);
}
