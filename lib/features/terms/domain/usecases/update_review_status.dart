import '../entities/term.dart';
import '../repositories/term_repository.dart';

class UpdateReviewStatus {
  final TermRepository repository;
  UpdateReviewStatus(this.repository);

  Future<void> call(String id, ReviewStatus status) =>
      repository.updateReviewStatus(id, status);
}
