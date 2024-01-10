// ignore_for_file: public_member_api_docs
@internal
library;

import 'package:meta/meta.dart';

import '../api/runtime_api.dart';
import '../query_builder/query_builder.dart';
import '../types/mapping.dart';

typedef JsonObject = Map<String, Object?>;

class TypeDescription {
  final DriftSqlType? type;
  final String? customTypeName;

  TypeDescription({this.type, this.customTypeName});

  factory TypeDescription.fromDrift(GenerationContext ctx, BaseSqlType type) {
    return switch (type) {
      DriftSqlType() => TypeDescription(type: type),
      CustomSqlType() ||
      DialectAwareSqlType() =>
        TypeDescription(customTypeName: type.sqlTypeName(ctx)),
    };
  }

  factory TypeDescription.fromJson(JsonObject obj) {
    final typeName = obj['type'] as String?;

    return TypeDescription(
      type: typeName != null ? DriftSqlType.values.byName(typeName) : null,
      customTypeName: obj['customTypeName'] as String?,
    );
  }

  JsonObject toJson() {
    return {
      'type': type?.name,
      'customTypeName': customTypeName,
    };
  }
}

class ColumnDescription {
  final String name;
  final TypeDescription type;
  final bool isNullable;

  ColumnDescription(
      {required this.name, required this.type, required this.isNullable});

  factory ColumnDescription.fromDrift(
      GenerationContext ctx, GeneratedColumn column) {
    return ColumnDescription(
      name: column.name,
      type: TypeDescription.fromDrift(ctx, column.type),
      isNullable: column.$nullable,
    );
  }

  factory ColumnDescription.fromJson(JsonObject obj) {
    return ColumnDescription(
      name: obj['name'] as String,
      type: TypeDescription.fromJson(obj['type'] as JsonObject),
      isNullable: obj['isNullable'] as bool,
    );
  }

  JsonObject toJson() {
    return {
      'name': name,
      'type': type.toJson(),
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
      GenerationContext ctx, DatabaseSchemaEntity entity) {
    return EntityDescription(
      name: entity.entityName,
      type: switch (entity) {
        VirtualTableInfo() => 'virtual_table',
        TableInfo() => 'table',
        ViewInfo() => 'view',
        Index() => 'index',
        Trigger() => 'trigger',
        _ => 'unknown',
      },
      columns: switch (entity) {
        ResultSetImplementation() => [
            for (final column in entity.$columns)
              ColumnDescription.fromDrift(ctx, column),
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
  final bool dateTimeAsText;
  final List<EntityDescription> entities;

  late Map<String, EntityDescription> entitiesByName = {
    for (final entity in entities) entity.name: entity,
  };

  DatabaseDescription({required this.dateTimeAsText, required this.entities});

  factory DatabaseDescription.fromDrift(GeneratedDatabase database) {
    final context = GenerationContext.fromDb(database);

    return DatabaseDescription(
      dateTimeAsText: database.options
          .createTypeMapping(SqlDialect.sqlite)
          .storeDateTimesAsText,
      entities: [
        for (final entity in database.allSchemaEntities)
          EntityDescription.fromDrift(context, entity),
      ],
    );
  }

  factory DatabaseDescription.fromJson(JsonObject obj) {
    return DatabaseDescription(
      dateTimeAsText: obj['dateTimeAsText'] as bool,
      entities: (obj['entities'] as List<dynamic>)
          .map((e) => EntityDescription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  JsonObject toJson() {
    return <String, dynamic>{
      'dateTimeAsText': dateTimeAsText,
      'entities': [for (final entity in entities) entity.toJson()],
    };
  }
}
