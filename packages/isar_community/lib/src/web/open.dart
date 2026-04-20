// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:async';
import 'dart:js_interop';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/bindings.dart';
import 'package:isar_community/src/web/isar_collection_impl.dart';
import 'package:isar_community/src/web/isar_impl.dart';
import 'package:isar_community/src/web/isar_web.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart';

const String _defaultIsarJsUrl =
    String.fromEnvironment(
      'ISAR_WEB_URL',
      defaultValue: 'assets/packages/isar_community_flutter_libs/web/isar.js',
    );

bool _loaded = false;

String _runtimeAssetPath(IsarWebStorageKind runtime) => switch (runtime) {
  IsarWebStorageKind.indexedDbJsRuntime => _defaultIsarJsUrl,
  IsarWebStorageKind.opfsWasmRuntime => _defaultIsarJsUrl,
};

List<int> _getWebOffsets(int propertiesCount) => [
  for (var i = 0; i < propertiesCount; i++) i,
  propertiesCount,
];

void _initializeOffsets(
  IsarImpl isar,
  CollectionSchema<dynamic> schema,
) {
  for (final embeddedSchema in schema.embeddedSchemas.values) {
    isar.offsets.putIfAbsent(
      embeddedSchema.type,
      () => _getWebOffsets(embeddedSchema.properties.length),
    );
  }
}

Future<void> initializeIsarWeb([String? jsUrl]) async {
  if (_loaded) {
    return;
  }
  final script = HTMLScriptElement();
  script.type = 'text/javascript';
  script.src = jsUrl ?? _defaultIsarJsUrl;
  script.async = true;

  final completer = Completer<void>();
  script.onload = ((Event _) {
    _loaded = true;
    completer.complete();
  }).toJS;
  script.onerror = ((Event _) {
    completer.completeError(IsarError('Failed to load Isar'));
  }).toJS;

  document.head!.append(script);
  await completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
    throw IsarError('Failed to load Isar');
  },);
}

IsarWebStorageKind _parseStorageKind(String kind) => switch (kind) {
  'indexedDbJsRuntime' => IsarWebStorageKind.indexedDbJsRuntime,
  'opfsWasmRuntime' => IsarWebStorageKind.opfsWasmRuntime,
  _ => throw UnsupportedError('Unknown Isar web storage kind: $kind'),
};

Future<List<IsarWebStorageKind>> getAvailableWebStorageKinds() async {
  await initializeIsarWeb();
  return getAvailableIsarWebStorageKindNames().map(_parseStorageKind).toList();
}

Future<List<IsarWebStorageKind>> getSupportedWebStorageKinds() async {
  await initializeIsarWeb();
  return getSupportedIsarWebStorageKindNames().map(_parseStorageKind).toList();
}

@visibleForTesting
void doNotInitializeIsarWeb() {
  _loaded = true;
}

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
  IsarWebStorageKind? webStorage,
}) async {
  final runtime = webStorage ?? IsarWebStorageKind.indexedDbJsRuntime;
  final supportedRuntimes = await getSupportedWebStorageKinds();
  if (!supportedRuntimes.contains(runtime)) {
    throw UnsupportedError(
      'The requested Isar web storage runtime $runtime is not enabled.',
    );
  }

  await initializeIsarWeb(_runtimeAssetPath(runtime));
  final schemasJson = schemas.map((e) => e.toJson());
  final instance = await openIsarJs(
    name,
    schemasJson.toList(),
    relaxedDurability,
    runtime.name,
  ).toDart;
  final isar = IsarImpl(name, instance);
  final cols = <Type, IsarCollection<dynamic>>{};
  for (final schema in schemas) {
    final col = instance.getCollection(schema.name);
    final offsets = _getWebOffsets(schema.properties.length);
    _initializeOffsets(isar, schema);
    schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
      isar.offsets[OBJ] = offsets;
      cols[OBJ] = IsarCollectionImpl<OBJ>(
        isar: isar,
        native: col,
        schema: schema,
      );
    });
  }

  isar.attachCollections(cols);
  return isar;
}

Isar openIsarSync({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
  IsarWebStorageKind? webStorage,
}) =>
    unsupportedOnWeb();
