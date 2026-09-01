// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tombstone_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TombstoneModelAdapter extends TypeAdapter<TombstoneModel> {
  @override
  final typeId = 3;

  @override
  TombstoneModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TombstoneModel()
      ..id = fields[0] as String
      ..entityType = fields[1] as String
      ..deletedAtMs = (fields[2] as num).toInt();
  }

  @override
  void write(BinaryWriter writer, TombstoneModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.deletedAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TombstoneModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
