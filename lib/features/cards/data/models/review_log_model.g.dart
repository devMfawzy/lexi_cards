// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewLogModelAdapter extends TypeAdapter<ReviewLogModel> {
  @override
  final typeId = 2;

  @override
  ReviewLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewLogModel()
      ..id = fields[0] as String
      ..cardId = fields[1] as String
      ..reviewedAt = fields[2] as DateTime
      ..rating = (fields[3] as num).toInt()
      ..previousIntervalDays = (fields[4] as num).toInt()
      ..newIntervalDays = (fields[5] as num).toInt()
      ..previousEaseFactor = (fields[6] as num).toDouble()
      ..newEaseFactor = (fields[7] as num).toDouble();
  }

  @override
  void write(BinaryWriter writer, ReviewLogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardId)
      ..writeByte(2)
      ..write(obj.reviewedAt)
      ..writeByte(3)
      ..write(obj.rating)
      ..writeByte(4)
      ..write(obj.previousIntervalDays)
      ..writeByte(5)
      ..write(obj.newIntervalDays)
      ..writeByte(6)
      ..write(obj.previousEaseFactor)
      ..writeByte(7)
      ..write(obj.newEaseFactor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
