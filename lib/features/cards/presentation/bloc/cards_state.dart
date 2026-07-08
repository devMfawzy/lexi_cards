import 'package:equatable/equatable.dart';
import '../../domain/entities/flashcard.dart';

class CardsState extends Equatable {
  final List<Flashcard> cards;
  final bool isLoading;
  final String? errorMessage;

  const CardsState({
    this.cards = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CardsState copyWith({
    List<Flashcard>? cards,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CardsState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [cards, isLoading, errorMessage];
}
