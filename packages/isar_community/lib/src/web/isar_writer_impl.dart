// ignore_for_file: public_member_api_docs

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/isar_reader_impl.dart';
import 'package:js/js_util.dart';
import 'package:meta/dart2js.dart';

class IsarWriterImpl implements IsarWriter {
  IsarWriterImpl(
    this.object,
    this.propertyNames,
    this.propertyNamesByOffsets,
  );

  final Object object;
  final List<String> propertyNames;
  final Map<List<int>, List<String>> propertyNamesByOffsets;

  @tryInline
  String _name(int offset) => propertyNames[offset];

  @tryInline
  void _set(int offset, dynamic value) {
    setProperty(object, _name(offset), value);
  }

  @tryInline
  @override
  void writeBool(int offset, bool? value) {
    final number = value ?? false
        ? 1
        : value == false
            ? 0
            : nullNumber;
    _set(offset, number);
  }

  @tryInline
  @override
  void writeByte(int offset, int value) {
    _set(offset, value);
  }

  @tryInline
  @override
  void writeInt(int offset, int? value) {
    _set(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeFloat(int offset, double? value) {
    _set(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeLong(int offset, int? value) {
    _set(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeDouble(int offset, double? value) {
    _set(offset, value ?? nullNumber);
  }

  @tryInline
  @override
  void writeDateTime(int offset, DateTime? value) {
    _set(offset, value?.toUtc().millisecondsSinceEpoch ?? nullNumber);
  }

  @tryInline
  @override
  void writeString(int offset, String? value) {
    _set(offset, value ?? nullNumber);
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
      final object = newObject<Object>();
      final offsets = allOffsets[T]!;
      final writer = IsarWriterImpl(
        object,
        propertyNamesByOffsets[offsets]!,
        propertyNamesByOffsets,
      );
      serialize(value, writer, offsets, allOffsets);
      _set(offset, object);
    }
  }

  @tryInline
  @override
  void writeByteList(int offset, List<int>? values) {
    _set(offset, values ?? nullNumber);
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
    _set(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeIntList(int offset, List<int?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _set(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeFloatList(int offset, List<double?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _set(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeLongList(int offset, List<int?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _set(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeDoubleList(int offset, List<double?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _set(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeDateTimeList(int offset, List<DateTime?>? values) {
    final list = values
        ?.map((e) => e?.toUtc().millisecondsSinceEpoch ?? nullNumber)
        .toList();
    _set(offset, list ?? nullNumber);
  }

  @tryInline
  @override
  void writeStringList(int offset, List<String?>? values) {
    final list = values?.map((e) => e ?? nullNumber).toList();
    _set(offset, list ?? nullNumber);
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
      final offsets = allOffsets[T]!;
      final list = values.map((e) {
        if (e != null) {
          final object = newObject<Object>();
          final writer = IsarWriterImpl(
            object,
            propertyNamesByOffsets[offsets]!,
            propertyNamesByOffsets,
          );
          serialize(e, writer, offsets, allOffsets);
          return object;
        }
      }).toList();
      _set(offset, list);
    }
  }
}
