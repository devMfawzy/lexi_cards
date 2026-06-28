import 'package:equatable/equatable.dart';

class TermSet extends Equatable {
  final String id;
  final String name;
  final String targetLanguage;
  final DateTime createdAt;

  const TermSet({
    required this.id,
    required this.name,
    required this.targetLanguage,
    required this.createdAt,
  });

  TermSet copyWith({
    String? id,
    String? name,
    String? targetLanguage,
    DateTime? createdAt,
  }) {
    return TermSet(
      id: id ?? this.id,
      name: name ?? this.name,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, targetLanguage, createdAt];
}
