// ignore_for_file: public_member_api_docs

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/isar_reader_impl.dart';
import 'package:meta/dart2js.dart';

class IsarWriterImpl implements IsarWriter {
  IsarWriterImpl(this.object);

  final Map<String, Object?> object;

  @tryInline
  void _setValue(int offset, Object? value) {
    object[offset.toString()] = value;
  }

  @tryInline
  @override
  void writeBool(int offset, bool? value) {
    final number = value ?? false
        ? 1
        : value == false
            ? 0
            : nullNumber;
    _setValue(offset, number);
  }

  @tryInline
  @override
  void writeByte(int offset, int value) {
    _setValue(offset, value);
  }

  @tryInline
  @override
  void writeInt(int offset, int? value) {
    _setValue(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeFloat(int offset, double? value) {
    _setValue(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeLong(int offset, int? value) {
    _setValue(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeDouble(int offset, double? value) {
    _setValue(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeDateTime(int offset, DateTime? value) {
    _setValue(offset, value?.toUtc().millisecondsSinceEpoch ?? nullNumber);
  }

  @tryInline
  @override
  void writeString(int offset, String? value) {
    _setValue(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeObject<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    T? value,
  ) {
    if (value != null) {
      final object = <String, Object?>{};
      final writer = IsarWriterImpl(object);
      serialize(value, writer, allOffsets[T]!, allOffsets);
      _setValue(offset, object);
    }
  }

  @tryInline
  @override
  void writeByteList(int offset, List<int>? values) {
    _setValue(offset, values ?? nullNumber);
  }

  @tryInline
  @override
  void writeBoolList(int offset, List<bool?>? values) {
    final list = values
        ?.map(
          (e) => e == false
              ? 0
              : e ?? false
                  ? 1
                  : nullNumber,
        )
        .toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeIntList(int offset, List<int?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeFloatList(int offset, List<double?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeLongList(int offset, List<int?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeDoubleList(int offset, List<double?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeDateTimeList(int offset, List<DateTime?>? values) {
    final list = values
        ?.map((e) => e?.toUtc().millisecondsSinceEpoch ?? nullNumber)
        .toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeStringList(int offset, List<String?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _setValue(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeObjectList<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    List<T?>? values,
  ) {
    if (values != null) {
      final list = values.map((e) {
        if (e != null) {
          final object = <String, Object?>{};
          final writer = IsarWriterImpl(object);
          serialize(e, writer, allOffsets[T]!, allOffsets);
          return object;
        }
      }).toList();
      _setValue(offset, list);
    }
  }
}
