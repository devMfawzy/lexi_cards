import 'package:equatable/equatable.dart';

enum ReviewStatus { fresh, learning, known }

class Term extends Equatable {
  final String id;
  final String setId;
  final String text;
  final List<String> phrases;
  final ReviewStatus reviewStatus;
  final DateTime createdAt;

  const Term({
    required this.id,
    required this.setId,
    required this.text,
    required this.phrases,
    required this.reviewStatus,
    required this.createdAt,
  });

  Term copyWith({
    String? id,
    String? setId,
    String? text,
    List<String>? phrases,
    ReviewStatus? reviewStatus,
    DateTime? createdAt,
  }) {
    return Term(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      text: text ?? this.text,
      phrases: phrases ?? this.phrases,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, setId, text, phrases, reviewStatus, createdAt];
}
