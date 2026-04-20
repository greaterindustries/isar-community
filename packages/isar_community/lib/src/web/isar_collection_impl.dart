// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/bindings.dart';
import 'package:isar_community/src/web/isar_impl.dart';
import 'package:isar_community/src/web/isar_reader_impl.dart';
import 'package:isar_community/src/web/isar_web.dart';
import 'package:isar_community/src/web/isar_writer_impl.dart';
import 'package:isar_community/src/web/query_build.dart';
import 'package:meta/dart2js.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  IsarCollectionImpl({
    required this.isar,
    required this.native,
    required this.schema,
  });

  @override
  final IsarImpl isar;
  final IsarCollectionJs native;

  @override
  final CollectionSchema<OBJ> schema;

  @override
  String get name => schema.name;

  late final _offsets = isar.offsets[OBJ]!;

  @tryInline
  Id _deserializeId(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    throw StateError('Missing Isar object id for collection $name');
  }

  @tryInline
  List<dynamic> _asList(Object? value) {
    if (value is List) {
      return value;
    }
    if (value is Iterable) {
      return value.toList();
    }
    return const [];
  }

  @tryInline
  Map<String, Object?> _serializeObject(OBJ object) {
    final jsObj = <String, Object?>{};
    final writer = IsarWriterImpl(jsObj);
    schema.serialize(object, writer, _offsets, isar.offsets);
    final id = schema.getId(object);
    jsObj[idName] = id;
    // Keep a public mirror for the JS bridge because some wasm/jsify paths
    // drop leading-underscore keys before the object reaches the storage layer.
    jsObj['id'] = id;
    return jsObj;
  }

  @tryInline
  IndexKey _buildIndexKey(
    String indexName,
    Map<String, Object?> serializedObject,
  ) {
    final index = schema.index(indexName);
    return [
      for (final property in index.properties)
        () {
          final propertySchema = schema.property(property.name);
          final offsetKey = _offsets[propertySchema.id].toString();
          return serializedObject[property.name] ?? serializedObject[offsetKey];
        }(),
    ];
  }

  Future<Id?> _getExistingIdByIndex(
    IsarTxnJs txn,
    String indexName,
    IndexKey key,
  ) async {
    final objects = jsValueToDart(
      await native.getAllByIndex(txn, indexName, [key]).toDart,
    );
    final existingObjects = _asList(objects);
    if (existingObjects.isEmpty) {
      return null;
    }

    final existingObject = existingObjects.first;
    if (existingObject is! Object) {
      return null;
    }

    final existingMap = Map<dynamic, dynamic>.from(existingObject as Map);
    final existingId = existingMap[idName];
    if (existingId == null) {
      return null;
    }

    return _deserializeId(existingId);
  }

  @tryInline
  OBJ deserializeObject(Object object) {
    final map = Map<dynamic, dynamic>.from(object as Map);
    final id = _deserializeId(map[idName]);
    final reader = IsarReaderImpl(object);
    return schema.deserialize(id, reader, _offsets, isar.offsets);
  }

  @tryInline
  List<OBJ?> deserializeObjects(dynamic objects) {
    final list = _asList(objects);
    final results = <OBJ?>[];
    for (final object in list) {
      results.add(object is Object ? deserializeObject(object) : null);
    }
    return results;
  }

  @override
  Future<List<OBJ?>> getAll(List<Id> ids) {
    return isar.getTxn(false, (IsarTxnJs txn) async {
      final objects = jsValueToDart(await native.getAll(txn, ids).toDart);
      return deserializeObjects(objects);
    });
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(false, (IsarTxnJs txn) async {
      final objects = jsValueToDart(
        await native.getAllByIndex(txn, indexName, keys).toDart,
      );
      return deserializeObjects(objects);
    });
  }

  @override
  List<OBJ?> getAllSync(List<Id> ids) => unsupportedOnWeb();

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys) =>
      unsupportedOnWeb();

  @override
  Future<List<Id>> putAll(List<OBJ> objects) {
    return putAllByIndex(null, objects);
  }

  @override
  List<int> putAllSync(List<OBJ> objects, {bool saveLinks = true}) =>
      unsupportedOnWeb();

  @override
  Future<List<Id>> putAllByIndex(String? indexName, List<OBJ> objects) {
    return isar.getTxn(true, (IsarTxnJs txn) async {
      if (indexName == null) {
        final serialized = objects.map(_serializeObject).toList();
        final ids = jsValueToDart(await native.putAll(txn, serialized).toDart);
        final idList = _asList(ids).map(_deserializeId).toList();
        for (var i = 0; i < objects.length; i++) {
          schema.attach(this, idList[i], objects[i]);
        }
        return idList;
      }

      final resolvedIdsByKey = <String, Id>{};
      final idList = <Id>[];
      for (final object in objects) {
        final jsObj = _serializeObject(object);
        final key = _buildIndexKey(indexName, jsObj);
        final keySignature = stringify(key);

        final resolvedId = resolvedIdsByKey[keySignature] ??
            await _getExistingIdByIndex(txn, indexName, key);
        if (resolvedId != null) {
          jsObj[idName] = resolvedId;
        }

        final ids = jsValueToDart(await native.putAll(txn, [jsObj]).toDart);
        final id = _deserializeId(_asList(ids).first);
        resolvedIdsByKey[keySignature] = id;
        idList.add(id);
        schema.attach(this, id, object);
      }

      return idList;
    });
  }

  @override
  List<Id> putAllByIndexSync(
    String indexName,
    List<OBJ> objects, {
    bool saveLinks = true,
  }) =>
      unsupportedOnWeb();

  @override
  Future<int> deleteAll(List<Id> ids) async {
    await isar.getTxn(true, (IsarTxnJs txn) {
      return native.deleteAll(txn, ids).toDart;
    });
    return ids.length;
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(true, (IsarTxnJs txn) {
      return native
          .deleteAllByIndex(txn, indexName, keys)
          .toDart
          .then((value) => (jsValueToDart(value) as num).toInt());
    });
  }

  @override
  int deleteAllSync(List<Id> ids) => unsupportedOnWeb();

  @override
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys) =>
      unsupportedOnWeb();

  @override
  Future<void> clear() {
    return isar.getTxn(true, (IsarTxnJs txn) {
      return native.clear(txn).toDart;
    });
  }

  @override
  void clearSync() => unsupportedOnWeb();

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) {
    return isar.getTxn(true, (IsarTxnJs txn) async {
      await native.putAll(txn, json).toDart;
    });
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) {
    final json = jsonDecode(const Utf8Decoder().convert(jsonBytes)) as List;
    return importJson(json.cast());
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json) => unsupportedOnWeb();

  @override
  void importJsonRawSync(Uint8List jsonBytes) => unsupportedOnWeb();

  @override
  Future<int> count() => where().count();

  @override
  int countSync() => unsupportedOnWeb();

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) =>
      unsupportedOnWeb();

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) {
    StopWatchingJs? stop;
    final controller = StreamController<void>(onCancel: () => stop?.stop());

    final callback = (() => controller.add(null)).toJS;
    stop = native.watchLazy(callback);

    return controller.stream;
  }

  @override
  Stream<OBJ?> watchObject(
    Id id, {
    bool fireImmediately = false,
    bool deserialize = true,
  }) {
    StopWatchingJs? stop;
    final controller = StreamController<OBJ?>(onCancel: () => stop?.stop());

    final callback = ((JSAny? obj) {
      final value = jsValueToDart(obj);
      final object = deserialize && value != null
          ? deserializeObject(value as Object)
          : null;
      controller.add(object);
    }).toJS;
    stop = native.watchObject(id, callback);

    return controller.stream;
  }

  @override
  Stream<void> watchObjectLazy(Id id, {bool fireImmediately = false}) =>
      watchObject(id, deserialize: false);

  @override
  Query<T> buildQuery<T>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    return buildWebQuery(
      this,
      whereClauses,
      whereDistinct,
      whereSort,
      filter,
      sortBy,
      distinctBy,
      offset,
      limit,
      property,
    );
  }

  @override
  Future<void> verify(List<OBJ> objects) => unsupportedOnWeb();

  @override
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) =>
      unsupportedOnWeb();
}
