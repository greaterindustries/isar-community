// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/bindings.dart';
import 'package:isar_community/src/web/isar_collection_impl.dart';
import 'package:isar_community/src/web/isar_web.dart';

typedef QueryDeserialize<T> = T Function(Object);

class QueryImpl<T> extends Query<T> {
  QueryImpl(this.col, this.queryJs, this.deserialize, this.propertyName);
  final IsarCollectionImpl<dynamic> col;
  final QueryJs queryJs;
  final QueryDeserialize<T> deserialize;
  final String? propertyName;

  List<dynamic> _asList(Object? value) {
    if (value is List) {
      return value;
    }
    if (value is Iterable) {
      return value.toList();
    }
    return const [];
  }

  List<T> _deserializeList(Object? value) {
    final items = _asList(value);
    final results = <T>[];
    for (final item in items) {
      results.add(deserialize(item as Object));
    }
    return results;
  }

  @override
  Isar get isar => col.isar;

  @override
  Future<T?> findFirst() {
    return col.isar.getTxn<T?>(false, (IsarTxnJs txn) async {
      final result = jsValueToDart(await queryJs.findFirst(txn).toDart);
      if (result == null) {
        return null;
      }
      return deserialize(result as Object);
    });
  }

  @override
  T? findFirstSync() => unsupportedOnWeb();

  @override
  Future<List<T>> findAll() {
    return col.isar.getTxn<List<T>>(false, (IsarTxnJs txn) async {
      final result = jsValueToDart(await queryJs.findAll(txn).toDart);
      return _deserializeList(result);
    });
  }

  @override
  List<T> findAllSync() => unsupportedOnWeb();

  @override
  Future<R?> aggregate<R>(AggregationOp op) {
    return col.isar.getTxn(false, (IsarTxnJs txn) async {
      final property = propertyName ?? col.schema.idName;
      final propertyKey = property;

      num? result;
      switch (op) {
        case AggregationOp.min:
          result =
              jsValueToDart(await queryJs.min(txn, propertyKey).toDart)
                  as num?;
          break;
        case AggregationOp.max:
          result =
              jsValueToDart(await queryJs.max(txn, propertyKey).toDart)
                  as num?;
          break;
        case AggregationOp.sum:
          result =
              jsValueToDart(await queryJs.sum(txn, propertyKey).toDart)
                  as num?;
          break;
        case AggregationOp.average:
          result =
              jsValueToDart(await queryJs.average(txn, propertyKey).toDart)
                  as num?;
          break;
        case AggregationOp.count:
          result = jsValueToDart(await queryJs.count(txn).toDart) as num?;
          break;
        // ignore: no_default_cases
        default:
          throw UnimplementedError();
      }

      if (result == null) {
        return null;
      }

      if (R == DateTime) {
        return DateTime.fromMillisecondsSinceEpoch(result.toInt()).toLocal()
            as R;
      } else if (R == int) {
        return result.toInt() as R;
      } else if (R == double) {
        return result.toDouble() as R;
      } else {
        return null;
      }
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) => unsupportedOnWeb();

  @override
  Future<bool> deleteFirst() {
    return col.isar.getTxn(true, (IsarTxnJs txn) {
      return queryJs
          .deleteFirst(txn)
          .toDart
          .then((value) => jsValueToDart(value) == true);
    });
  }

  @override
  bool deleteFirstSync() => unsupportedOnWeb();

  @override
  Future<int> deleteAll() {
    return col.isar.getTxn(true, (IsarTxnJs txn) {
      return queryJs
          .deleteAll(txn)
          .toDart
          .then((value) => (jsValueToDart(value) as num).toInt());
    });
  }

  @override
  int deleteAllSync() => unsupportedOnWeb();

  @override
  Stream<List<T>> watch({bool fireImmediately = false}) {
    StopWatchingJs? stop;
    final controller = StreamController<List<T>>(onCancel: () => stop?.stop());

    if (fireImmediately) {
      findAll().then(controller.add);
    }

    final callback = ((JSArray<JSAny?> results) {
      controller.add(_deserializeList(jsValueToDart(results)));
    }).toJS;
    stop = col.native.watchQuery(queryJs, callback);

    return controller.stream;
  }

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) {
    StopWatchingJs? stop;
    final controller = StreamController<void>(onCancel: () => stop?.stop());

    final callback = (() {
      controller.add(null);
    }).toJS;
    stop = col.native.watchQueryLazy(queryJs, callback);

    return controller.stream;
  }

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback) async {
    return col.isar.getTxn(false, (IsarTxnJs txn) async {
      final result = jsValueToDart(await queryJs.findAll(txn).toDart);
      final jsonStr = stringify(result);
      return callback(const Utf8Encoder().convert(jsonStr));
    });
  }

  @override
  Future<List<Map<String, dynamic>>> exportJson() {
    return col.isar.getTxn(false, (IsarTxnJs txn) async {
      final result = _asList(jsValueToDart(await queryJs.findAll(txn).toDart));
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  @override
  R exportJsonRawSync<R>(R Function(Uint8List) callback) => unsupportedOnWeb();

  @override
  List<Map<String, dynamic>> exportJsonSync({bool primitiveNull = true}) =>
      unsupportedOnWeb();
}
