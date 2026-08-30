// ignore_for_file: public_member_api_docs
@internal
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../database/db_base.dart';
import '../query_builder.dart';

typedef JsonObject = Map<String, Object?>;

class TypeDescription {
  final BuiltinSqlType? builtin;
  final String? sqlTypeName;

  TypeDescription({this.builtin, this.sqlTypeName});

  factory TypeDescription.fromDrift(DriftDialect dialect, SqlType type) {
    return TypeDescription(
      builtin: type is BuiltinSqlType ? type : null,
      sqlTypeName: type.typeName(dialect),
    );
  }

  factory TypeDescription.fromJson(JsonObject obj) {
    final builtinName = obj['builtin'] as String?;

    return TypeDescription(
      builtin: builtinName != null
          ? BuiltinSqlType.values.byName(builtinName)
          : null,
      sqlTypeName: obj['sqlTypeName'] as String?,
    );
  }

  JsonObject toJson() {
    return {'builtin': builtin?.name, 'sqlTypeName': sqlTypeName};
  }
}

class ColumnDescription {
  final String name;
  final TypeDescription type;
  final bool isNullable;

  ColumnDescription({
    required this.name,
    required this.type,
    required this.isNullable,
  });

  factory ColumnDescription.fromDrift(
    DriftDialect dialect,
    SchemaColumn column,
  ) {
    return ColumnDescription(
      name: column.name,
      type: TypeDescription.fromDrift(dialect, column.sqlType),
      isNullable:
          column is! TableColumn ||
          column.constraints.every((e) => e is! ColumnNotNullConstraint),
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
    return {'name': name, 'type': type.toJson(), 'isNullable': isNullable};
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

  EntityDescription({
    required this.name,
    required this.type,
    required this.columns,
  });

  factory EntityDescription.fromDrift(
    DriftDialect dialect,
    DatabaseSchemaEntity entity,
  ) {
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
        SchemaEntityWithResultSet() => [
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
          for (final column in columns!) column.toJson(),
      ],
    };
  }
}

class DatabaseDescription {
  final List<EntityDescription> entities;

  late Map<String, EntityDescription> entitiesByName = {
    for (final entity in entities) entity.name: entity,
  };

  DatabaseDescription({required this.entities});

  factory DatabaseDescription.fromDrift(GeneratedDatabase database) {
    return DatabaseDescription(
      entities: [
        for (final entity in database.schema)
          EntityDescription.fromDrift(database.dialect, entity),
      ],
    );
  }

  factory DatabaseDescription.fromJson(JsonObject obj) {
    return DatabaseDescription(
      entities: (obj['entities'] as List<dynamic>)
          .map((e) => EntityDescription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  JsonObject toJson() {
    return <String, dynamic>{
      'entities': [for (final entity in entities) entity.toJson()],
    };
  }
}

/// Encodes a Dart value that can appear as a SQL parameter or result to be
/// JSON serializable.
Object? encodeSqlValue(Object? value) {
  return switch (value) {
    null || String() || num() => value,
    final Uint8List binary => {'binary': base64.encode(binary)},
    _ => null,
  };
}

Object? decodeSqlValue(GeneratedDatabase db, Object? value) {
  final (type, mappedValue) = switch (value) {
    String() => (BuiltinSqlType.text, value),
    int() => (BuiltinSqlType.int, value),
    double() => (BuiltinSqlType.double, value),
    {'binary': final String binary} => (
      BuiltinSqlType.byteArray,
      base64.decode(binary),
    ),
    _ => (BuiltinSqlType.text, null),
  };

  return type.sqlParameter(db.dialect, mappedValue);
}
