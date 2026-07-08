import 'package:equatable/equatable.dart';
import '../../domain/entities/deck.dart';

class DeckSummary extends Equatable {
  final Deck deck;
  final int dueCount;
  final int newCount;

  const DeckSummary({
    required this.deck,
    required this.dueCount,
    required this.newCount,
  });

  @override
  List<Object?> get props => [deck, dueCount, newCount];
}

class DecksState extends Equatable {
  final List<DeckSummary> summaries;
  final bool isLoading;
  final String? errorMessage;

  const DecksState({
    this.summaries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DecksState copyWith({
    List<DeckSummary>? summaries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DecksState(
      summaries: summaries ?? this.summaries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [summaries, isLoading, errorMessage];
}
