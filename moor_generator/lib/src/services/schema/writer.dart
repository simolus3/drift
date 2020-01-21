import 'package:moor_generator/moor_generator.dart';

const _infoVersion = '0.1.0-dev-preview';

/// Utilities to transform moor schema entities to json.
class SchemaWriter {
  /// The parsed and resolved database for which the schema should be written.
  final Database db;

  final Map<MoorSchemaEntity, int> _entityIds = {};
  int _maxId = 0;

  SchemaWriter(this.db);

  int _idOf(MoorSchemaEntity entity) {
    return _entityIds.putIfAbsent(entity, () => _maxId++);
  }

  Map<String, dynamic> createSchemaJson() {
    return {
      '_meta': {
        'description': 'This file contains a serialized version of schema '
            'entities for moor.',
        'version': _infoVersion,
      },
      'entities': [
        for (final entity in db.entities) _entityToJson(entity),
      ],
    };
  }

  Map _entityToJson(MoorSchemaEntity entity) {
    String type;
    Map data;

    if (entity is MoorTable) {
      type = 'table';
      data = _tableData(entity);
    } else if (entity is MoorTrigger) {
      type = 'trigger';
      data = {
        'on': _idOf(entity.on),
        'refences_in_body': [
          for (final ref in entity.bodyReferences) _idOf(ref),
        ],
        'name': entity.displayName,
        'sql': entity.create,
      };
    } else if (entity is MoorIndex) {
      type = 'index';
      data = {
        'on': _idOf(entity.table),
        'name': entity.name,
        'sql': entity.createStmt,
      };
    } else if (entity is SpecialQuery) {
      type = 'special-query';
      data = {
        'scenario': 'create',
        'sql': entity.sql,
      };
    }

    return {
      'id': _idOf(entity),
      'references': [
        for (final reference in entity.references) _idOf(reference),
      ],
      'type': type,
      'data': data,
    };
  }

  Map _tableData(MoorTable table) {
    return {
      'name': table.sqlName,
      'was_declared_in_moor': table.isFromSql,
      'columns': [for (final column in table.columns) _columnData(column)],
      'is_virtual': table.isVirtualTable,
      if (table.isVirtualTable) 'create_virtual_stmt': table.createVirtual,
      if (table.overrideWithoutRowId != null)
        'without_rowid': table.overrideWithoutRowId,
      if (table.overrideTableConstraints != null)
        'constraints': table.overrideTableConstraints,
      if (table.primaryKey != null)
        'explicit_pk': [...table.primaryKey.map((c) => c.name.name)]
    };
  }

  Map _columnData(MoorColumn column) {
    return {
      'name': column.name.name,
      'moor_type': column.type.toString(),
      'nullable': column.nullable,
      'customConstraints': column.customConstraints,
      'default_dart': column.defaultArgument,
      'default_client_dart': column.clientDefaultCode,
      'dsl_features': [...column.features.map(_dslFeatureData)],
      if (column.typeConverter != null)
        'type_converter': {
          'dart_expr': column.typeConverter.expression.toSource(),
          'dart_type_name': column.typeConverter.mappedType.displayName,
        }
    };
  }

  dynamic _dslFeatureData(ColumnFeature feature) {
    if (feature is AutoIncrement) {
      return 'auto-increment';
    } else if (feature is PrimaryKey) {
      return 'primary-key';
    } else if (feature is LimitingTextLength) {
      return {
        'allowed-lengths': {
          'min': feature.minLength,
          'max': feature.maxLength,
        },
      };
    }
    return 'unknown';
  }
}
