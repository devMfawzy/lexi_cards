import 'package:equatable/equatable.dart';

class Deck extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const Deck({required this.id, required this.name, required this.createdAt});

  Deck copyWith({String? id, String? name, DateTime? createdAt}) {
    return Deck(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
