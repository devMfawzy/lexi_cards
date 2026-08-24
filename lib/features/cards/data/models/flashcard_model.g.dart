// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardModelAdapter extends TypeAdapter<FlashcardModel> {
  @override
  final typeId = 1;

  @override
  FlashcardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FlashcardModel()
      ..id = fields[0] as String
      ..deckId = fields[1] as String
      ..front = fields[2] as String
      ..back = fields[3] as String
      ..createdAt = fields[4] as DateTime
      ..state = (fields[5] as num).toInt()
      ..dueDate = fields[6] as DateTime
      ..intervalDays = (fields[7] as num).toInt()
      ..easeFactor = (fields[8] as num).toDouble()
      ..learningStepIndex = (fields[9] as num).toInt()
      ..lapses = (fields[10] as num).toInt()
      ..reviewCount = (fields[11] as num).toInt();
  }

  @override
  void write(BinaryWriter writer, FlashcardModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deckId)
      ..writeByte(2)
      ..write(obj.front)
      ..writeByte(3)
      ..write(obj.back)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.intervalDays)
      ..writeByte(8)
      ..write(obj.easeFactor)
      ..writeByte(9)
      ..write(obj.learningStepIndex)
      ..writeByte(10)
      ..write(obj.lapses)
      ..writeByte(11)
      ..write(obj.reviewCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
