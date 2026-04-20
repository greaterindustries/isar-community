// ignore_for_file: public_member_api_docs

import 'package:isar_community/isar.dart';
import 'package:meta/dart2js.dart';

const nullNumber = double.negativeInfinity;
const idName = '_id';
const defaultIntValue = 0;
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

class IsarReaderImpl implements IsarReader {
  IsarReaderImpl(this.object);

  final Object object;

  dynamic _valueAt(int offset) => _map()[offset.toString()];

  Map<dynamic, dynamic> _map() => Map<dynamic, dynamic>.from(object as Map);

  List<dynamic>? _listValue(int offset) {
    final value = _valueAt(offset);
    if (value is List) {
      return value;
    }
    if (value is Iterable) {
      return value.toList();
    }
    return null;
  }

  num? _numberValue(Object? value) => value is num ? value : null;

  int _readRequiredInt(Object? value) {
    final number = _numberValue(value);
    if (number == null || number == nullNumber) {
      return defaultIntValue;
    }
    return number.toInt();
  }

  int? _readNullableInt(Object? value) {
    final number = _numberValue(value);
    if (number == null || number == nullNumber) {
      return null;
    }
    return number.toInt();
  }

  double _readRequiredDouble(Object? value) {
    final number = _numberValue(value);
    return number?.toDouble() ?? nullNumber;
  }

  double? _readNullableDouble(Object? value) {
    final number = _numberValue(value);
    if (number == null || number == nullNumber) {
      return null;
    }
    return number.toDouble();
  }

  DateTime _readRequiredDateTime(Object? value) {
    final millis = _readNullableInt(value);
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal()
        : nullDate;
  }

  DateTime? _readNullableDateTime(Object? value) {
    final millis = _readNullableInt(value);
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal()
        : null;
  }

  @tryInline
  @override
  bool readBool(int offset) {
    final value = _valueAt(offset);
    return value == 1;
  }

  @tryInline
  @override
  bool? readBoolOrNull(int offset) {
    final value = _valueAt(offset);
    return value == 0
        ? false
        : value == 1
        ? true
        : null;
  }

  @tryInline
  @override
  int readByte(int offset) => _readRequiredInt(_valueAt(offset));

  @tryInline
  @override
  int? readByteOrNull(int offset) => _readNullableInt(_valueAt(offset));

  @tryInline
  @override
  int readInt(int offset) => _readRequiredInt(_valueAt(offset));

  @tryInline
  @override
  int? readIntOrNull(int offset) => _readNullableInt(_valueAt(offset));

  @tryInline
  @override
  double readFloat(int offset) => _readRequiredDouble(_valueAt(offset));

  @tryInline
  @override
  double? readFloatOrNull(int offset) => _readNullableDouble(_valueAt(offset));

  @tryInline
  @override
  int readLong(int offset) => _readRequiredInt(_valueAt(offset));

  @tryInline
  @override
  int? readLongOrNull(int offset) => _readNullableInt(_valueAt(offset));

  @tryInline
  @override
  double readDouble(int offset) => _readRequiredDouble(_valueAt(offset));

  @tryInline
  @override
  double? readDoubleOrNull(int offset) => _readNullableDouble(_valueAt(offset));

  @tryInline
  @override
  DateTime readDateTime(int offset) => _readRequiredDateTime(_valueAt(offset));

  @tryInline
  @override
  DateTime? readDateTimeOrNull(int offset) =>
      _readNullableDateTime(_valueAt(offset));

  @tryInline
  @override
  String readString(int offset) {
    final value = _valueAt(offset);
    return value is String ? value : '';
  }

  @tryInline
  @override
  String? readStringOrNull(int offset) {
    final value = _valueAt(offset);
    return value is String ? value : null;
  }

  @tryInline
  @override
  T? readObjectOrNull<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  ) {
    final value = _valueAt(offset);
    if (value is Object) {
      final reader = IsarReaderImpl(value);
      return deserialize(0, reader, allOffsets[T]!, allOffsets);
    } else {
      return null;
    }
  }

  @tryInline
  @override
  List<bool>? readBoolList(int offset) {
    final value = _listValue(offset);
    return value?.map((e) => e == 1).toList();
  }

  @tryInline
  @override
  List<bool?>? readBoolOrNullList(int offset) {
    final value = _listValue(offset);
    return value
        ?.map(
          (e) => e == 0
              ? false
              : e == 1
              ? true
              : null,
        )
        .toList();
  }

  @tryInline
  @override
  List<int>? readByteList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readRequiredInt).toList();
  }

  @tryInline
  @override
  List<int>? readIntList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readRequiredInt).toList();
  }

  @tryInline
  @override
  List<int?>? readIntOrNullList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readNullableInt).toList();
  }

  @tryInline
  @override
  List<double>? readFloatList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readRequiredDouble).toList();
  }

  @tryInline
  @override
  List<double?>? readFloatOrNullList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readNullableDouble).toList();
  }

  @tryInline
  @override
  List<int>? readLongList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readRequiredInt).toList();
  }

  @tryInline
  @override
  List<int?>? readLongOrNullList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readNullableInt).toList();
  }

  @tryInline
  @override
  List<double>? readDoubleList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readRequiredDouble).toList();
  }

  @tryInline
  @override
  List<double?>? readDoubleOrNullList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readNullableDouble).toList();
  }

  @tryInline
  @override
  List<DateTime>? readDateTimeList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readRequiredDateTime).toList();
  }

  @tryInline
  @override
  List<DateTime?>? readDateTimeOrNullList(int offset) {
    final value = _listValue(offset);
    return value?.map(_readNullableDateTime).toList();
  }

  @tryInline
  @override
  List<String>? readStringList(int offset) {
    final value = _listValue(offset);
    return value?.map((e) => e is String ? e : '').toList();
  }

  @tryInline
  @override
  List<String?>? readStringOrNullList(int offset) {
    final value = _listValue(offset);
    return value?.map((e) => e is String ? e : null).toList();
  }

  @tryInline
  @override
  List<T>? readObjectList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
    T defaultValue,
  ) {
    final value = _listValue(offset);
    return value?.map((e) {
      if (e is Object) {
        final reader = IsarReaderImpl(e);
        return deserialize(0, reader, allOffsets[T]!, allOffsets);
      } else {
        return defaultValue;
      }
    }).toList();
  }

  @tryInline
  @override
  List<T?>? readObjectOrNullList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  ) {
    final value = _listValue(offset);
    return value?.map((e) {
      if (e is Object) {
        final reader = IsarReaderImpl(e);
        return deserialize(0, reader, allOffsets[T]!, allOffsets);
      } else {
        return null;
      }
    }).toList();
  }
}
