import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:isar_community/isar.dart';

import 'package:isar_community_generator/src/object_info.dart';

const _webIdMask = (1 << 53) - 1;

int _webHash(String input) {
  final bytes = utf8.encode(input);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask64 = (BigInt.one << 64) - BigInt.one;
  for (final byte in bytes) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask64;
  }
  return (hash & BigInt.from(_webIdMask)).toInt();
}

List<int> _splitId(int id) {
  final hi = id >> 32;
  final lo = id & 0xffffffff;
  return [hi, lo];
}

String _formatId(String helperPrefix, String webKey, int id) {
  final parts = _splitId(id);
  final webId = _webHash(webKey);
  return '${helperPrefix}IsWeb ? $webId : ${helperPrefix}Id64(${parts[0]}, ${parts[1]})';
}

String generateSchema(ObjectInfo object) {
  final helperPrefix = '_isar${object.dartName.capitalize()}';
  var code = '''
    const bool ${helperPrefix}IsWeb = bool.fromEnvironment('dart.library.html');

    int ${helperPrefix}Id64(int hi, int lo) => (hi << 32) | (lo & 0xffffffff);

  ''';

  code += 'final ${object.dartName.capitalize()}Schema = ';
  if (!object.isEmbedded) {
    code += 'CollectionSchema(';
  } else {
    code += 'Schema(';
  }

  final properties = object.objectProperties
      .mapIndexed(
        (i, e) => "r'${e.isarName}': ${_generatePropertySchema(object, i)}",
      )
      .join(',');

  code += '''
    name: r'${object.isarName}',
    id: ${_formatId(helperPrefix, 'collection:${object.isarName}', object.id)},
    properties: {$properties},

    estimateSize: ${object.estimateSizeName},
    serialize: ${object.serializeName},
    deserialize: ${object.deserializeName},
    deserializeProp: ${object.deserializePropName},''';

  if (!object.isEmbedded) {
    final indexes = object.indexes
        .map((e) => "r'${e.name}': ${_generateIndexSchema(object, helperPrefix, e)}")
        .join(',');
    final links = object.links
        .map((e) => "r'${e.isarName}': ${_generateLinkSchema(object, helperPrefix, e)}")
        .join(',');
    final embeddedSchemas = object.embeddedDartNames.entries
        .map((e) => "r'${e.key}': ${e.value.capitalize()}Schema")
        .join(',');

    code += '''
      idName: r'${object.idProperty.isarName}',
      indexes: {$indexes},
      links: {$links},
      embeddedSchemas: {$embeddedSchemas},

      getId: ${object.getIdName},
      getLinks: ${object.getLinksName},
      attach: ${object.attachName},
      version: '${Isar.version}',
    ''';
  }

  return '$code);';
}

String _generatePropertySchema(ObjectInfo object, int index) {
  final property = object.objectProperties[index];
  var enumMap = '';
  if (property.isEnum) {
    enumMap = 'enumMap: ${property.enumValueMapName(object)},';
  }
  var target = '';
  if (property.targetIsarName != null) {
    target = "target: r'${property.targetIsarName}',";
  }
  return '''
  PropertySchema(
    id: $index,
    name: r'${property.isarName}',
    type: IsarType.${property.isarType.name},
    $enumMap
    $target
  )
  ''';
}

String _generateIndexSchema(ObjectInfo object, String helperPrefix, ObjectIndex index) {
  final properties = index.properties.map((e) {
    return '''
      IndexPropertySchema(
        name: r'${e.property.isarName}',
        type: IndexType.${e.type.name},
        caseSensitive: ${e.caseSensitive},
      )''';
  }).join(',');

  return '''
    IndexSchema(
      id: ${_formatId(helperPrefix, 'index:${object.isarName}:${index.name}', index.id)},
      name: r'${index.name}',
      unique: ${index.unique},
      replace: ${index.replace},
      properties: [$properties],
    )''';
}

String _generateLinkSchema(ObjectInfo object, String helperPrefix, ObjectLink link) {
  var linkName = '';
  if (link.isBacklink) {
    linkName = "linkName: r'${link.targetLinkIsarName}',";
  }
  return '''
    LinkSchema(
      id: ${_formatId(
        helperPrefix,
        'link:${object.isarName}:${link.isarName}:${link.targetCollectionIsarName}:${link.targetLinkIsarName ?? ''}:${link.isBacklink}',
        link.id(object.isarName),
      )},
      name: r'${link.isarName}',
      target: r'${link.targetCollectionIsarName}',
      single: ${link.isSingle},
      $linkName
    )''';
}
