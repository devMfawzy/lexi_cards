// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'term_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TermModelAdapter extends TypeAdapter<TermModel> {
  @override
  final int typeId = 1;

  @override
  TermModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TermModel()
      ..id = fields[0] as String
      ..setId = fields[1] as String
      ..text = fields[2] as String
      ..phrases = (fields[3] as List).cast<String>()
      ..reviewStatus = fields[4] as int
      ..createdAt = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, TermModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.setId)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.phrases)
      ..writeByte(4)
      ..write(obj.reviewStatus)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
