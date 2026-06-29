import 'package:lexi_cards/features/terms/domain/entities/term.dart';
import 'package:lexi_cards/features/terms/domain/repositories/term_repository.dart';


class UpdateReviewStatus {
  final TermRepository repository;
  UpdateReviewStatus(this.repository);

  Future<void> call(String id, ReviewStatus status) =>
      repository.updateReviewStatus(id, status);
}
