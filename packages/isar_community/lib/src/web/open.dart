// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:html';
import 'dart:js_util';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/bindings.dart';
import 'package:isar_community/src/web/isar_collection_impl.dart';
import 'package:isar_community/src/web/isar_impl.dart';
import 'package:isar_community/src/web/isar_web.dart';
import 'package:meta/meta.dart';

bool _loaded = false;
Future<void> initializeIsarWeb([String? jsUrl]) async {
  if (_loaded) {
    return;
  }
  _loaded = true;

  final script = ScriptElement();
  script.type = 'text/javascript';
  // ignore: unsafe_html
  script.src = jsUrl ?? 'https://unpkg.com/isar@${Isar.version}/dist/index.js';
  script.async = true;
  document.head!.append(script);
  await script.onLoad.first.timeout(
    const Duration(seconds: 30),
    onTimeout: () {
      throw IsarError('Failed to load Isar');
    },
  );
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
}) async {
  await initializeIsarWeb();
  final propertyNamesByOffsets = <List<int>, List<String>>{};
  final schemasJson = schemas.map((schema) {
    final json = schema.toJson();
    json['embeddedSchemas'] =
        schema.embeddedSchemas.values.map((e) => e.toJson()).toList();
    return json;
  }).toList();
  final schemasJs = jsify(schemasJson) as List<dynamic>;
  final instance = await openIsarJs(name, schemasJs, relaxedDurability)
      .wait<IsarInstanceJs>();
  final isar = IsarImpl(name, instance);

  List<int> ensureOffsets(Schema<dynamic> schema) {
    final existing = isar.offsets[schema.type];
    if (existing != null) {
      propertyNamesByOffsets.putIfAbsent(
        existing,
        () =>
            schema.properties.values.map((property) => property.name).toList(),
      );
      return existing;
    }

    final propertyNames =
        schema.properties.values.map((property) => property.name).toList();
    final offsets =
        List<int>.generate(propertyNames.length + 1, (index) => index);
    isar.offsets[schema.type] = offsets;
    propertyNamesByOffsets[offsets] = propertyNames;
    return offsets;
  }

  void ensureOffsetsDeep(Schema<dynamic> schema) {
    ensureOffsets(schema);
    if (schema is CollectionSchema<dynamic>) {
      for (final embeddedSchema in schema.embeddedSchemas.values) {
        ensureOffsetsDeep(embeddedSchema);
      }
    }
  }

  for (final schema in schemas) {
    ensureOffsetsDeep(schema);
  }

  final cols = <Type, IsarCollection<dynamic>>{};
  for (final schema in schemas) {
    final col = instance.getCollection(schema.name);
    schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
      cols[OBJ] = IsarCollectionImpl<OBJ>(
        isar: isar,
        native: col,
        schema: schema,
        propertyNamesByOffsets: propertyNamesByOffsets,
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
}) =>
    unsupportedOnWeb();
