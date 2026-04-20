// ignore_for_file: public_member_api_docs

@JS()
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:isar_community/isar.dart';

String stringify(Object? value) => _stringify(value.jsify()).toDart;

int idbCmp(Object? value1, Object? value2) =>
    _idbCmp(value1.jsify(), value2.jsify()).toDartInt;

Map<String, dynamic> jsMapToDart(Object obj) =>
    Map<String, dynamic>.from(jsValueToDart(obj)! as Map);

Object? jsValueToDart(Object? value) {
  if (value == null) {
    return null;
  }

  final dartValue = value is JSAny ? value.dartify() : value;
  if (dartValue is List) {
    return dartValue.map(jsValueToDart).toList();
  }
  if (dartValue is Map) {
    final map = <String, dynamic>{};
    for (final entry in dartValue.entries) {
      map[entry.key.toString()] = jsValueToDart(entry.value);
    }
    return map;
  }
  return dartValue;
}

JSArray<JSAny?> listToJSArray(Iterable<Object?> values) =>
    values.map((value) => value.jsify()).toList().toJS;

@JS('JSON.stringify')
external JSString _stringify(JSAny? value);

@JS('indexedDB.cmp')
external JSNumber _idbCmp(JSAny? value1, JSAny? value2);

@JS('openIsar')
external JSPromise<IsarInstanceJs> _openIsarJs(
  JSString name,
  JSArray<JSAny?> schemas,
  JSBoolean relaxedDurability,
  JSString runtime,
);

@JS('getSupportedIsarWebStorageKinds')
external JSArray<JSString> _getSupportedIsarWebStorageKindsJs();

@JS('getAvailableIsarWebStorageKinds')
external JSArray<JSString> _getAvailableIsarWebStorageKindsJs();

JSPromise<IsarInstanceJs> openIsarJs(
  String name,
  List<Object?> schemas,
  bool relaxedDurability,
  String runtime,
) =>
    _openIsarJs(
      name.toJS,
      listToJSArray(schemas),
      relaxedDurability.toJS,
      runtime.toJS,
    );

List<String> getSupportedIsarWebStorageKindNames() =>
    _getSupportedIsarWebStorageKindsJs().toDart.map((kind) => kind.toDart).toList();

List<String> getAvailableIsarWebStorageKindNames() =>
    _getAvailableIsarWebStorageKindsJs().toDart.map((kind) => kind.toDart).toList();

extension type StopWatchingJs._(JSFunction _) implements JSFunction {
  void stop() =>
      this.callMethodVarArgs('apply'.toJS, [null, JSArray<JSAny?>()]);
}

extension type IsarTxnJs._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> commit();

  external void abort();

  bool get write => (getProperty('write'.toJS) as JSBoolean).toDart;
}

extension type IsarInstanceJs._(JSObject _) implements JSObject {
  IsarTxnJs beginTxn(bool write) =>
      IsarTxnJs._(
        callMethodVarArgs('beginTxn'.toJS, [write.toJS]) as JSObject,
      );

  IsarCollectionJs getCollection(String name) =>
      IsarCollectionJs._(
        callMethodVarArgs('getCollection'.toJS, [name.toJS]) as JSObject,
      );

  JSPromise<JSAny?> close(bool deleteFromDisk) =>
      callMethodVarArgs('close'.toJS, [deleteFromDisk.toJS])
          as JSPromise<JSAny?>;
}

extension type IsarCollectionJs._(JSObject _) implements JSObject {
  IsarLinkJs getLink(String name) =>
      IsarLinkJs._(
        callMethodVarArgs('getLink'.toJS, [name.toJS]) as JSObject,
      );

  JSPromise<JSAny?> getAll(IsarTxnJs txn, List<Id> ids) =>
      callMethodVarArgs('getAll'.toJS, [txn, listToJSArray(ids)])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> getAllByIndex(
    IsarTxnJs txn,
    String indexName,
    List<IndexKey> values,
  ) => callMethodVarArgs('getAllByIndex'.toJS, [
    txn,
    indexName.toJS,
    listToJSArray(values),
  ]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> putAll(IsarTxnJs txn, List<Object?> objects) =>
      callMethodVarArgs('putAll'.toJS, [txn, listToJSArray(objects)])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> deleteAll(IsarTxnJs txn, List<Id> ids) =>
      callMethodVarArgs('deleteAll'.toJS, [txn, listToJSArray(ids)])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> deleteAllByIndex(
    IsarTxnJs txn,
    String indexName,
    List<IndexKey> keys,
  ) => callMethodVarArgs('deleteAllByIndex'.toJS, [
    txn,
    indexName.toJS,
    listToJSArray(keys),
  ]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> clear(IsarTxnJs txn) =>
      callMethodVarArgs('clear'.toJS, [txn]) as JSPromise<JSAny?>;

  external StopWatchingJs watchLazy(JSFunction callback);

  external StopWatchingJs watchObject(Id id, JSFunction callback);

  external StopWatchingJs watchQuery(QueryJs query, JSFunction callback);

  external StopWatchingJs watchQueryLazy(QueryJs query, JSFunction callback);
}

extension type IsarLinkJs._(JSObject _) implements JSObject {
  JSPromise<JSAny?> update(
    IsarTxnJs txn,
    bool backlink,
    Id id,
    List<Id> addedTargets,
    List<Id> deletedTargets,
  ) => callMethodVarArgs('update'.toJS, [
    txn,
    backlink.toJS,
    id.toJS,
    listToJSArray(addedTargets),
    listToJSArray(deletedTargets),
  ]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> clear(IsarTxnJs txn, Id id, bool backlink) =>
      callMethodVarArgs('clear'.toJS, [txn, id.toJS, backlink.toJS])
          as JSPromise<JSAny?>;
}

@JS('Function')
extension type FilterJs._(JSFunction _) implements JSFunction {
  external factory FilterJs(String id, String obj, String method);
}

@JS('Function')
extension type SortCmpJs._(JSFunction _) implements JSFunction {
  external factory SortCmpJs(String a, String b, String method);
}

@JS('Function')
extension type DistinctValueJs._(JSFunction _) implements JSFunction {
  external factory DistinctValueJs(String obj, String method);
}

@JS('IsarQuery')
extension type QueryJs._(JSObject _) implements JSObject {
  external factory QueryJs(
    IsarCollectionJs collection,
    JSArray<JSAny?> whereClauses,
    JSBoolean whereDistinct,
    JSBoolean whereAscending,
    FilterJs? filter,
    SortCmpJs? sortCmp,
    DistinctValueJs? distinctValue,
    int? offset,
    int? limit,
  );

  JSPromise<JSAny?> findFirst(IsarTxnJs txn) =>
      callMethodVarArgs('findFirst'.toJS, [txn]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> findAll(IsarTxnJs txn) =>
      callMethodVarArgs('findAll'.toJS, [txn]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> deleteFirst(IsarTxnJs txn) =>
      callMethodVarArgs('deleteFirst'.toJS, [txn]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> deleteAll(IsarTxnJs txn) =>
      callMethodVarArgs('deleteAll'.toJS, [txn]) as JSPromise<JSAny?>;

  JSPromise<JSAny?> min(IsarTxnJs txn, String propertyName) =>
      callMethodVarArgs('min'.toJS, [txn, propertyName.toJS])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> max(IsarTxnJs txn, String propertyName) =>
      callMethodVarArgs('max'.toJS, [txn, propertyName.toJS])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> sum(IsarTxnJs txn, String propertyName) =>
      callMethodVarArgs('sum'.toJS, [txn, propertyName.toJS])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> average(IsarTxnJs txn, String propertyName) =>
      callMethodVarArgs('average'.toJS, [txn, propertyName.toJS])
          as JSPromise<JSAny?>;

  JSPromise<JSAny?> count(IsarTxnJs txn) =>
      callMethodVarArgs('count'.toJS, [txn]) as JSPromise<JSAny?>;
}
