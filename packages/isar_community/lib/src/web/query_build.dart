// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:isar_community/isar.dart';
import 'package:isar_community/src/web/bindings.dart';
import 'package:isar_community/src/web/isar_collection_impl.dart';
import 'package:isar_community/src/web/isar_web.dart';
import 'package:isar_community/src/web/query_impl.dart';
import 'package:web/web.dart';

Query<T> buildWebQuery<T, OBJ>(
  IsarCollectionImpl<OBJ> col,
  List<WhereClause> whereClauses,
  bool whereDistinct,
  Sort whereSort,
  FilterOperation? filter,
  List<SortProperty> sortBy,
  List<DistinctProperty> distinctBy,
  int? offset,
  int? limit,
  String? property,
) {
  final whereClausesJs = whereClauses.map((wc) {
    if (wc is IdWhereClause) {
      return _buildIdWhereClause(wc);
    } else if (wc is IndexWhereClause) {
      return _buildIndexWhereClause(col.schema, wc);
    } else {
      return _buildLinkWhereClause(col, wc as LinkWhereClause);
    }
  }).toList();

  final filterJs = filter != null ? _buildFilter(col.schema, filter) : null;
  final sortJs = sortBy.isNotEmpty ? _buildSort(col.schema, sortBy) : null;
  final distinctJs = distinctBy.isNotEmpty
      ? _buildDistinct(col.schema, distinctBy)
      : null;

  final queryJs = QueryJs(
    col.native,
    listToJSArray(whereClausesJs),
    whereDistinct.toJS,
    (whereSort == Sort.asc).toJS,
    filterJs,
    sortJs,
    distinctJs,
    offset,
    limit,
  );

  final QueryDeserialize<T> deserialize = (Object value) =>
      col.deserializeObject(value) as T;

  return QueryImpl<T>(col, queryJs, deserialize, property);
}

dynamic _valueToJs(dynamic value) {
  if (value == null) {
    return double.negativeInfinity;
  } else if (value == true) {
    return 1;
  } else if (value == false) {
    return 0;
  } else if (value is DateTime) {
    return value.toUtc().millisecondsSinceEpoch;
  } else if (value is List) {
    return value.map(_valueToJs).toList();
  } else {
    return value;
  }
}

Object _buildIdWhereClause(IdWhereClause wc) {
  final clause = JSObject();
  clause['range'] = _buildKeyRange(
    wc.lower,
    wc.upper,
    wc.includeLower,
    wc.includeUpper,
  );
  return clause;
}

Object _buildIndexWhereClause(
  CollectionSchema<dynamic> schema,
  IndexWhereClause wc,
) {
  final index = schema.index(wc.indexName);

  final lower = wc.lower?.toList();
  final upper = wc.upper?.toList();
  if (upper != null) {
    while (index.properties.length > upper.length) {
      upper.add([]);
    }
  }

  dynamic lowerUnwrapped = wc.lower;
  if (index.properties.length == 1 && lower != null) {
    lowerUnwrapped = lower.isNotEmpty ? lower[0] : null;
  }

  dynamic upperUnwrapped = upper;
  if (index.properties.length == 1 && upper != null) {
    upperUnwrapped = upper.isNotEmpty ? upper[0] : double.infinity;
  }

  final clause = JSObject();
  clause['indexName'] = wc.indexName.toJS;
  clause['range'] = _buildKeyRange(
    wc.lower != null ? _valueToJs(lowerUnwrapped) : null,
    wc.upper != null ? _valueToJs(upperUnwrapped) : null,
    wc.includeLower,
    wc.includeUpper,
  );
  return clause;
}

Object _buildLinkWhereClause(
  IsarCollectionImpl<dynamic> col,
  LinkWhereClause wc,
) {
  // ignore: unused_local_variable
  final linkCol =
      col.isar.getCollectionByNameInternal(wc.linkCollection)!
          as IsarCollectionImpl;
  //final backlinkLinkName = linkCol.schema.backlinkLinkNames[wc.linkName];
  final clause = JSObject();
  clause['linkCollection'] = wc.linkCollection.toJS;
  //..linkName = backlinkLinkName ?? wc.linkName
  //..backlink = backlinkLinkName != null
  clause['id'] = wc.id.toJS;
  return clause;
}

IDBKeyRange? _buildKeyRange(
  dynamic lower,
  dynamic upper,
  bool includeLower,
  bool includeUpper,
) {
  final lowerValue = lower as Object?;
  final upperValue = upper as Object?;

  if (lowerValue != null) {
    if (upperValue != null) {
      final boundsEqual = idbCmp(lowerValue, upperValue) == 0;
      if (boundsEqual) {
        if (includeLower && includeUpper) {
          return IDBKeyRange.only(_jsKeyValue(lowerValue));
        } else {
          // empty range
          return IDBKeyRange.upperBound(double.negativeInfinity.jsify(), true);
        }
      }

      return IDBKeyRange.bound(
        _jsKeyValue(lowerValue),
        _jsKeyValue(upperValue),
        !includeLower,
        !includeUpper,
      );
    } else {
      return IDBKeyRange.lowerBound(_jsKeyValue(lowerValue), !includeLower);
    }
  } else if (upperValue != null) {
    return IDBKeyRange.upperBound(_jsKeyValue(upperValue), !includeUpper);
  }
  return null;
}

JSAny? _jsKeyValue(Object? value) => value?.jsify();

FilterJs? _buildFilter(
  CollectionSchema<dynamic> schema,
  FilterOperation filter,
) {
  final filterStr = _buildFilterOperation(schema, filter);
  if (filterStr != null) {
    return FilterJs('id', 'obj', 'return $filterStr');
  } else {
    return null;
  }
}

String? _buildFilterOperation(
  CollectionSchema<dynamic> schema,
  FilterOperation filter,
) {
  if (filter is FilterGroup) {
    return _buildFilterGroup(schema, filter);
  } else if (filter is LinkFilter) {
    unsupportedOnWeb();
  } else if (filter is FilterCondition) {
    return _buildCondition(schema, filter);
  } else {
    return null;
  }
}

String? _buildFilterGroup(CollectionSchema<dynamic> schema, FilterGroup group) {
  final builtConditions = group.filters
      .map((op) => _buildFilterOperation(schema, op))
      .where((e) => e != null)
      .toList();

  if (builtConditions.isEmpty) {
    return null;
  }

  if (group.type == FilterGroupType.not) {
    return '!(${builtConditions[0]})';
  } else if (builtConditions.length == 1) {
    return builtConditions[0];
  } else if (group.type == FilterGroupType.xor) {
    final conditions = builtConditions.join(',');
    return 'IsarQuery.xor($conditions)';
  } else {
    final op = group.type == FilterGroupType.or ? '||' : '&&';
    final condition = builtConditions.join(op);
    return '($condition)';
  }
}

String _buildCondition(
  CollectionSchema<dynamic> schema,
  FilterCondition condition,
) {
  dynamic prepareFilterValue(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is String) {
      return stringify(value);
    } else {
      return _valueToJs(value);
    }
  }

  final isListOp =
      condition.type != FilterConditionType.isNull &&
      condition.type != FilterConditionType.listLength &&
      schema.property(condition.property).type.isList;
  final propertyAccessor = condition.property == schema.idName
      ? 'id'
      : 'obj.${condition.property}';
  final accessor = condition.property == schema.idName
      ? 'id'
      : propertyAccessor;
  final variable = isListOp ? 'e' : accessor;

  final cond = _buildConditionInternal(
    conditionType: condition.type,
    variable: variable,
    val1: prepareFilterValue(condition.value1),
    include1: condition.include1,
    val2: prepareFilterValue(condition.value2),
    include2: condition.include2,
    caseSensitive: condition.caseSensitive,
  );

  if (isListOp) {
    return '(Array.isArray($accessor) && $accessor.some(e => $cond))';
  } else {
    return cond;
  }
}

String _buildConditionInternal({
  required FilterConditionType conditionType,
  required String variable,
  required Object? val1,
  required bool include1,
  required Object? val2,
  required bool include2,
  required bool caseSensitive,
}) {
  final isNull = '($variable == null || $variable === -Infinity)';
  switch (conditionType) {
    case FilterConditionType.equalTo:
      if (val1 == null) {
        return isNull;
      } else if (val1 is String && !caseSensitive) {
        return '$variable?.toLowerCase() === ${val1.toLowerCase()}';
      } else {
        return '$variable === $val1';
      }
    case FilterConditionType.between:
      final val = val1 ?? val2;
      final lowerOp = include1 ? '>=' : '>';
      final upperOp = include2 ? '<=' : '<';
      if (val == null) {
        return isNull;
      } else if ((val1 is String?) && (val2 is String?) && !caseSensitive) {
        final lower = val1?.toLowerCase() ?? '-Infinity';
        final upper = val2?.toLowerCase() ?? '-Infinity';
        final variableLc = '$variable?.toLowerCase() ?? -Infinity';
        final lowerCond = 'indexedDB.cmp($variableLc, $lower) $lowerOp 0';
        final upperCond = 'indexedDB.cmp($variableLc, $upper) $upperOp 0';
        return '($lowerCond && $upperCond)';
      } else {
        final lowerCond =
            'indexedDB.cmp($variable, ${val1 ?? '-Infinity'}) $lowerOp 0';
        final upperCond =
            'indexedDB.cmp($variable, ${val2 ?? '-Infinity'}) $upperOp 0';
        return '($lowerCond && $upperCond)';
      }
    case FilterConditionType.lessThan:
      if (val1 == null) {
        if (include1) {
          return isNull;
        } else {
          return 'false';
        }
      } else {
        final op = include1 ? '<=' : '<';
        if (val1 is String && !caseSensitive) {
          return 'indexedDB.cmp($variable?.toLowerCase() ?? '
              '-Infinity, ${val1.toLowerCase()}) $op 0';
        } else {
          return 'indexedDB.cmp($variable, $val1) $op 0';
        }
      }
    case FilterConditionType.greaterThan:
      if (val1 == null) {
        if (include1) {
          return 'true';
        } else {
          return '!$isNull';
        }
      } else {
        final op = include1 ? '>=' : '>';
        if (val1 is String && !caseSensitive) {
          return 'indexedDB.cmp($variable?.toLowerCase() ?? '
              '-Infinity, ${val1.toLowerCase()}) $op 0';
        } else {
          return 'indexedDB.cmp($variable, $val1) $op 0';
        }
      }
    case FilterConditionType.startsWith:
    case FilterConditionType.endsWith:
    case FilterConditionType.contains:
      final op = conditionType == FilterConditionType.startsWith
          ? 'startsWith'
          : conditionType == FilterConditionType.endsWith
          ? 'endsWith'
          : 'includes';
      if (val1 is String) {
        final isString = 'typeof $variable == "string"';
        if (!caseSensitive) {
          return '($isString && $variable.toLowerCase() '
              '.$op(${val1.toLowerCase()}))';
        } else {
          return '($isString && $variable.$op($val1))';
        }
      } else {
        throw IsarError('Unsupported type for condition');
      }
    case FilterConditionType.matches:
      throw UnimplementedError();
    case FilterConditionType.isNull:
      return isNull;
    // ignore: no_default_cases
    default:
      throw UnimplementedError();
  }
}

SortCmpJs _buildSort(
  CollectionSchema<dynamic> schema,
  List<SortProperty> properties,
) {
  final sort = properties
      .map((e) {
        final op = e.sort == Sort.asc ? '' : '-';
        final accessor = e.property == schema.idName
            ? '._id'
            : '.${e.property}';
        return '${op}indexedDB.cmp(a$accessor ?? "-Infinity", b$accessor ?? "-Infinity")';
      })
      .join('||');
  return SortCmpJs('a', 'b', 'return $sort');
}

DistinctValueJs _buildDistinct(
  CollectionSchema<dynamic> schema,
  List<DistinctProperty> properties,
) {
  final distinct = properties
      .map((e) {
        final accessor = e.property == schema.idName
            ? '._id'
            : '.${e.property}';
        if (e.caseSensitive == false) {
          return e.property == schema.idName
              ? 'obj$accessor?.toString().toLowerCase() ?? "-Infinity"'
              : 'obj$accessor?.toLowerCase() ?? "-Infinity"';
        } else {
          return 'obj$accessor?.toString() ?? "-Infinity"';
        }
      })
      .join('+');
  return DistinctValueJs('obj', 'return $distinct');
}
