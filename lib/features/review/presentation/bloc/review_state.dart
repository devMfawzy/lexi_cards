import 'package:equatable/equatable.dart';
import '../../../cards/domain/entities/flashcard.dart';
import '../../domain/entities/rating.dart';

class ReviewState extends Equatable {
  final List<Flashcard> queue;
  // Cards rated this session that landed back in learning/relearning (short
  // SM-2 steps, minutes away) rather than graduating — held here until their
  // due date arrives, then spliced back into [queue] so a single session
  // queue can re-surface a just-failed card instead of only doing so on the
  // next full reload.
  final List<Flashcard> pendingRequeue;
  final bool showAnswer;
  final int reviewedCount;
  final bool isLoading;
  final String? errorMessage;
  final Map<Rating, Duration> previews;

  const ReviewState({
    this.queue = const [],
    this.pendingRequeue = const [],
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
    List<Flashcard>? pendingRequeue,
    bool? showAnswer,
    int? reviewedCount,
    bool? isLoading,
    String? errorMessage,
    Map<Rating, Duration>? previews,
  }) {
    return ReviewState(
      queue: queue ?? this.queue,
      pendingRequeue: pendingRequeue ?? this.pendingRequeue,
      showAnswer: showAnswer ?? this.showAnswer,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      previews: previews ?? this.previews,
    );
  }

  @override
  List<Object?> get props => [
    queue,
    pendingRequeue,
    showAnswer,
    reviewedCount,
    isLoading,
    errorMessage,
    previews,
  ];
}
