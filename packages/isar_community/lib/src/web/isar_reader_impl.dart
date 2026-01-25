// ignore_for_file: public_member_api_docs

import 'package:isar_community/isar.dart';
import 'package:js/js_util.dart';
import 'package:meta/dart2js.dart';

const nullNumber = double.negativeInfinity;
const idName = '_id';
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

class IsarReaderImpl implements IsarReader {
  IsarReaderImpl(
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
  dynamic _get(int offset) => getProperty<dynamic>(object, _name(offset));

  @tryInline
  @override
  bool readBool(int offset) {
    final value = _get(offset);
    return value == 1;
  }

  @tryInline
  @override
  bool? readBoolOrNull(int offset) {
    final value = _get(offset);
    return value == 0
        ? false
        : value == 1
            ? true
            : null;
  }

  @tryInline
  @override
  int readByte(int offset) {
    final value = _get(offset);
    return value is num ? value.toInt() : nullNumber as int;
  }

  @tryInline
  @override
  int? readByteOrNull(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber ? value.toInt() : null;
  }

  @tryInline
  @override
  int readInt(int offset) {
    final value = _get(offset);
    return value is num ? value.toInt() : nullNumber as int;
  }

  @tryInline
  @override
  int? readIntOrNull(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber ? value.toInt() : null;
  }

  @tryInline
  @override
  double readFloat(int offset) {
    final value = _get(offset);
    return value is num ? value.toDouble() : nullNumber;
  }

  @tryInline
  @override
  double? readFloatOrNull(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber ? value.toDouble() : null;
  }

  @tryInline
  @override
  int readLong(int offset) {
    final value = _get(offset);
    return value is num ? value.toInt() : nullNumber as int;
  }

  @tryInline
  @override
  int? readLongOrNull(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber ? value.toInt() : null;
  }

  @tryInline
  @override
  double readDouble(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber ? value.toDouble() : nullNumber;
  }

  @tryInline
  @override
  double? readDoubleOrNull(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber ? value.toDouble() : null;
  }

  @tryInline
  @override
  DateTime readDateTime(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber
        ? DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
            .toLocal()
        : nullDate;
  }

  @tryInline
  @override
  DateTime? readDateTimeOrNull(int offset) {
    final value = _get(offset);
    return value is num && value != nullNumber
        ? DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
            .toLocal()
        : null;
  }

  @tryInline
  @override
  String readString(int offset) {
    final value = _get(offset);
    return value is String ? value : '';
  }

  @tryInline
  @override
  String? readStringOrNull(int offset) {
    final value = _get(offset);
    return value is String ? value : null;
  }

  @tryInline
  @override
  T? readObjectOrNull<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  ) {
    final value = _get(offset);
    if (value is Object) {
      final offsets = allOffsets[T]!;
      final reader = IsarReaderImpl(
        value,
        propertyNamesByOffsets[offsets]!,
        propertyNamesByOffsets,
      );
      return deserialize(0, reader, offsets, allOffsets);
    } else {
      return null;
    }
  }

  @tryInline
  @override
  List<bool>? readBoolList(int offset) {
    final value = _get(offset);
    return value is List ? value.map((e) => e == 1).toList() : null;
  }

  @tryInline
  @override
  List<bool?>? readBoolOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value
            .map(
              (e) => e == 0
                  ? false
                  : e == 1
                      ? true
                      : null,
            )
            .toList()
        : null;
  }

  @tryInline
  @override
  List<int>? readByteList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is num ? e.toInt() : nullNumber as int).toList()
        : null;
  }

  @tryInline
  @override
  List<int?>? readByteOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value
            .map((e) => e is num && e != nullNumber ? e.toInt() : null)
            .toList()
        : null;
  }

  @tryInline
  @override
  List<int>? readIntList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is num ? e.toInt() : nullNumber as int).toList()
        : null;
  }

  @tryInline
  @override
  List<int?>? readIntOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value
            .map((e) => e is num && e != nullNumber ? e.toInt() : null)
            .toList()
        : null;
  }

  @tryInline
  @override
  List<double>? readFloatList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is num ? e.toDouble() : nullNumber).toList()
        : null;
  }

  @tryInline
  @override
  List<double?>? readFloatOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value
            .map((e) => e is num && e != nullNumber ? e.toDouble() : null)
            .toList()
        : null;
  }

  @tryInline
  @override
  List<int>? readLongList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is num ? e.toInt() : nullNumber as int).toList()
        : null;
  }

  @tryInline
  @override
  List<int?>? readLongOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value
            .map((e) => e is num && e != nullNumber ? e.toInt() : null)
            .toList()
        : null;
  }

  @tryInline
  @override
  List<double>? readDoubleList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is num ? e.toDouble() : nullNumber).toList()
        : null;
  }

  @tryInline
  @override
  List<double?>? readDoubleOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value
            .map((e) => e is num && e != nullNumber ? e.toDouble() : null)
            .toList()
        : null;
  }

  @tryInline
  @override
  List<DateTime>? readDateTimeList(int offset) {
    final value = _get(offset);
    if (value is List) {
      return value
          .map(
            (e) => e is int && e != nullNumber
                ? DateTime.fromMillisecondsSinceEpoch(
                    e,
                    isUtc: true,
                  ).toLocal()
                : nullDate,
          )
          .toList();
    } else {
      return null;
    }
  }

  @tryInline
  @override
  List<DateTime?>? readDateTimeOrNullList(int offset) {
    final value = _get(offset);
    if (value is List) {
      return value
          .map(
            (e) => e is int && e != nullNumber
                ? DateTime.fromMillisecondsSinceEpoch(
                    e,
                    isUtc: true,
                  ).toLocal()
                : null,
          )
          .toList();
    } else {
      return null;
    }
  }

  @tryInline
  @override
  List<String>? readStringList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is String ? e : '').toList()
        : null;
  }

  @tryInline
  @override
  List<String?>? readStringOrNullList(int offset) {
    final value = _get(offset);
    return value is List
        ? value.map((e) => e is String ? e : null).toList()
        : null;
  }

  @tryInline
  @override
  List<T>? readObjectList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
    T defaultValue,
  ) {
    final value = _get(offset);
    if (value is List) {
      final offsets = allOffsets[T]!;
      return value.map((item) {
        if (item is Object) {
          final reader = IsarReaderImpl(
            item,
            propertyNamesByOffsets[offsets]!,
            propertyNamesByOffsets,
          );
          return deserialize(0, reader, offsets, allOffsets);
        }
        return defaultValue;
      }).toList();
    }
    return null;
  }

  @tryInline
  @override
  List<T?>? readObjectOrNullList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  ) {
    final value = _get(offset);
    if (value is List) {
      final offsets = allOffsets[T]!;
      return value.map((item) {
        if (item is Object) {
          final reader = IsarReaderImpl(
            item,
            propertyNamesByOffsets[offsets]!,
            propertyNamesByOffsets,
          );
          return deserialize(0, reader, offsets, allOffsets);
        }
        return null;
      }).toList();
    }
    return null;
  }
}
