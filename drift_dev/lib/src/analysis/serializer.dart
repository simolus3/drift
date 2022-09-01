import 'dart:convert' as convert;

import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/results/dart.dart';
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;

import 'results/column.dart';
import 'results/element.dart';
import 'results/table.dart';

class ElementSerializer {
  Map<String, Object?> serialize(DriftElement element) {
    if (element is DriftTable) {
      return {
        'type': 'table',
        'id': element.id.toJson(),
        'declaration': element.declaration.toJson(),
        'references': [
          for (final referenced in element.references)
            _serializeElementReference(referenced),
        ],
        'columns': [
          for (final column in element.columns) _serializeColumn(column),
        ],
      };
    }

    throw UnimplementedError('Unknown element $element');
  }

  Map<String, Object?> _serializeColumn(DriftColumn column) {
    return {
      'sqlType': column.sqlType.name,
      'nullable': column.nullable,
      'nameInSql': column.nameInSql,
      'nameInDart': column.nameInDart,
      'declaration': column.declaration.toJson(),
      'typeConverter': column.typeConverter?.toJson(),
      'clientDefaultCode': column.clientDefaultCode?.toJson(),
      'defaultArgument': column.clientDefaultCode?.toJson(),
      'overriddenJsonName': column.overriddenJsonName,
      'documentationComment': column.documentationComment,
      'constraints': [
        for (final constraint in column.constraints)
          _serializeColumnConstraint(constraint),
      ],
      'customConstraints': column.customConstraints,
    };
  }

  Map<String, Object?> _serializeColumnConstraint(
      DriftColumnConstraint constraint) {
    if (constraint is ForeignKeyReference) {
      return {
        'type': 'foreign_key',
        'column': _serializeColumnReference(constraint.otherColumn),
        'onUpdate': constraint.onUpdate?.name,
        'onDelete': constraint.onDelete?.name,
      };
    } else {
      throw UnimplementedError('Unsupported column constrain: $constraint');
    }
  }

  Map<String, Object?> _serializeElementReference(DriftElement element) {
    return element.id.toJson();
  }

  Map<String, Object?> _serializeColumnReference(DriftColumn column) {
    return {
      'table': _serializeElementReference(column.owner),
      'name': column.nameInSql,
    };
  }
}

abstract class ElementDeserializer {
  final Map<Uri, Map<String, Object?>> _loadedJson = {};
  final Map<DriftElementId, DriftElement> _deserializedElements = {};

  /// Loads the serialized definitions of all elements with a
  /// [DriftElementId.libraryUri] matching the [uri].
  Future<String> loadStateForUri(Uri uri);

  Future<DriftElement> _readElementReference(Map json) async {
    final id = DriftElementId.fromJson(json);

    final data = _loadedJson[id.libraryUri] ??= convert.json
        .decode(await loadStateForUri(id.libraryUri)) as Map<String, Object?>;

    return _deserializedElements[id] ??=
        await _readDriftElement(data[id.name] as Map);
  }

  Future<DriftColumn> _readDriftColumnReference(Map json) async {
    final table =
        (await _readElementReference(json['table'] as Map)) as DriftTable;
    final name = json['name'] as String;

    return table.columns.singleWhere((c) => c.nameInSql == name);
  }

  Future<DriftElement> _readDriftElement(Map json) async {
    final type = json['type'] as String;
    final id = DriftElementId.fromJson(json['id'] as Map);
    final declaration = DriftDeclaration.fromJson(json['declaration'] as Map);

    switch (type) {
      case 'table':
        return DriftTable(id, declaration, columns: [
          for (final rawColumn in json['columns'] as List)
            await _readColumn(rawColumn as Map),
        ]);
      default:
        throw UnimplementedError('Unsupported element type: $type');
    }
  }

  Future<DriftColumn> _readColumn(Map json) async {
    return DriftColumn(
      sqlType: DriftSqlType.values.byName(json['sqlType'] as String),
      nullable: json['nullable'] as bool,
      nameInSql: json['nameInSql'] as String,
      nameInDart: json['nameInDart'] as String,
      declaration: DriftDeclaration.fromJson(json['declaration'] as Map),
      typeConverter: json['typeConverter'] != null
          ? AppliedTypeConverter.fromJson(json['typeConverter'] as Map)
          : null,
      clientDefaultCode: json['clientDefaultCode'] != null
          ? AnnotatedDartCode.fromJson(json['clientDefaultCode'] as Map)
          : null,
      defaultArgument: json['defaultArgument'] != null
          ? AnnotatedDartCode.fromJson(json['defaultArgument'] as Map)
          : null,
      overriddenJsonName: json['overriddenJsonName'] as String?,
      documentationComment: json['documentationComment'] as String?,
      constraints: [
        for (final rawConstraint in json['constraints'] as List)
          await _readConstraint(rawConstraint as Map)
      ],
      customConstraints: json['customConstraints'] as String?,
    );
  }

  Future<DriftColumnConstraint> _readConstraint(Map json) async {
    final type = json['type'] as String;

    switch (type) {
      case 'foreign_key':
        ReferenceAction? readAction(String? value) {
          return value == null ? null : ReferenceAction.values.byName(value);
        }

        return ForeignKeyReference(
          await _readDriftColumnReference(json['column'] as Map),
          readAction(json['onUpdate'] as String?),
          readAction(json['onDelete'] as String?),
        );
      default:
        throw UnimplementedError('Unsupported constraint: $type');
    }
  }
}
