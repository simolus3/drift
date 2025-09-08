// ignore_for_file: public_member_api_docs
@internal
library;

import 'package:meta/meta.dart';

import '../../query_builder.dart';
import '../database/db_base.dart';
import 'dialects.dart';

typedef JsonObject = Map<String, Object?>;

class ColumnDescription {
  final String name;
  final String type;
  final bool isNullable;

  ColumnDescription(
      {required this.name, required this.type, required this.isNullable});

  factory ColumnDescription.fromDrift(
      DriftDialect dialect, SchemaColumn column) {
    return ColumnDescription(
      name: column.name,
      type: column.type.typeName(dialect),
      isNullable: column.isNullable,
    );
  }

  factory ColumnDescription.fromJson(JsonObject obj) {
    return ColumnDescription(
      name: obj['name'] as String,
      type: obj['type'] as String,
      isNullable: obj['isNullable'] as bool,
    );
  }

  JsonObject toJson() {
    return {
      'name': name,
      'type': type,
      'isNullable': isNullable,
    };
  }
}

class EntityDescription {
  final String name;
  final String type;
  final List<ColumnDescription>? columns;

  late Map<String, ColumnDescription> columnsByName = {
    for (final column in columns ?? const <ColumnDescription>[])
      column.name: column,
  };

  EntityDescription(
      {required this.name, required this.type, required this.columns});

  factory EntityDescription.fromDrift(
      DriftDialect dialect, DatabaseSchemaEntity entity) {
    return EntityDescription(
      name: entity.entityName,
      type: switch (entity) {
        VirtualTableInfo() => 'virtual_table',
        GeneratedTable() => 'table',
        GeneratedView() => 'view',
        Index() => 'index',
        Trigger() => 'trigger',
        _ => 'unknown',
      },
      columns: switch (entity) {
        ResultSet() => [
            for (final column in entity.columns)
              ColumnDescription.fromDrift(dialect, column),
          ],
        _ => null,
      },
    );
  }

  factory EntityDescription.fromJson(JsonObject obj) {
    return EntityDescription(
      name: obj['name'] as String,
      type: obj['type'] as String,
      columns: (obj['columns'] as List<dynamic>)
          .map((e) => ColumnDescription.fromJson(e as JsonObject))
          .toList(),
    );
  }

  JsonObject toJson() {
    return {
      'name': name,
      'type': type,
      'columns': [
        if (columns != null)
          for (final column in columns!) column.toJson()
      ],
    };
  }
}

class DatabaseDescription {
  final DriftDialect dialect;
  final List<EntityDescription> entities;

  late Map<String, EntityDescription> entitiesByName = {
    for (final entity in entities) entity.name: entity,
  };

  DatabaseDescription({required this.dialect, required this.entities});

  factory DatabaseDescription.fromDrift(GeneratedDatabase database) {
    return DatabaseDescription(
      dialect: database.dialect,
      entities: [
        for (final entity in database.allSchemaEntities)
          EntityDescription.fromDrift(database.dialect, entity),
      ],
    );
  }

  factory DatabaseDescription.fromJson(JsonObject obj) {
    return DatabaseDescription(
      dialect: deserializeDialect(obj['dialect'] as JsonObject),
      entities: (obj['entities'] as List<dynamic>)
          .map((e) => EntityDescription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  JsonObject toJson() {
    return <String, dynamic>{
      'dialect': serializeDialect(dialect),
      'entities': [for (final entity in entities) entity.toJson()],
    };
  }
}
