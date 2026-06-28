import '../entities/term.dart';
import '../repositories/term_repository.dart';

class AddTerm {
  final TermRepository repository;
  AddTerm(this.repository);

  Future<Term> call(String text, String setId) =>
      repository.addTerm(text, setId);
}
