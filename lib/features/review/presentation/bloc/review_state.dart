import 'package:equatable/equatable.dart';
import '../../../cards/domain/entities/flashcard.dart';
import '../../domain/entities/rating.dart';

class ReviewState extends Equatable {
  final List<Flashcard> queue;
  final bool showAnswer;
  final int reviewedCount;
  final bool isLoading;
  final String? errorMessage;
  final Map<Rating, Duration> previews;

  const ReviewState({
    this.queue = const [],
    this.showAnswer = false,
    this.reviewedCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.previews = const {},
  });

  Flashcard? get currentCard => queue.isEmpty ? null : queue.first;
  bool get isComplete => !isLoading && queue.isEmpty;

  ReviewState copyWith({
    List<Flashcard>? queue,
    bool? showAnswer,
    int? reviewedCount,
    bool? isLoading,
    String? errorMessage,
    Map<Rating, Duration>? previews,
  }) {
    return ReviewState(
      queue: queue ?? this.queue,
      showAnswer: showAnswer ?? this.showAnswer,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      previews: previews ?? this.previews,
    );
  }

  @override
  List<Object?> get props =>
      [queue, showAnswer, reviewedCount, isLoading, errorMessage, previews];
}
