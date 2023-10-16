// ignore_for_file: public_member_api_docs
@internal
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../api/runtime_api.dart';
import '../query_builder/query_builder.dart';
import '../types/mapping.dart';

part 'shared.g.dart';

typedef JsonObject = Map<String, Object?>;

@JsonSerializable()
class TypeDescription {
  final DriftSqlType? type;
  final String? customTypeName;

  TypeDescription({this.type, this.customTypeName});

  factory TypeDescription.fromDrift(GenerationContext ctx, BaseSqlType type) {
    return switch (type) {
      DriftSqlType() => TypeDescription(type: type),
      CustomSqlType<Object>() =>
        TypeDescription(customTypeName: type.sqlTypeName(ctx)),
    };
  }

  factory TypeDescription.fromJson(JsonObject obj) =>
      _$TypeDescriptionFromJson(obj);

  JsonObject toJson() => _$TypeDescriptionToJson(this);
}

@JsonSerializable()
class ColumnDescription {
  final String name;
  final TypeDescription? type;
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

  factory ColumnDescription.fromJson(JsonObject obj) =>
      _$ColumnDescriptionFromJson(obj);

  JsonObject toJson() => _$ColumnDescriptionToJson(this);
}

@JsonSerializable()
class EntityDescription {
  final String name;
  final String type;
  final List<ColumnDescription>? columns;

  EntityDescription(
      {required this.name, required this.type, required this.columns});

  factory EntityDescription.fromDrift(
      GenerationContext ctx, DatabaseSchemaEntity entity) {
    return EntityDescription(
      name: entity.entityName,
      type: switch (entity) {
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

  factory EntityDescription.fromJson(JsonObject obj) =>
      _$EntityDescriptionFromJson(obj);

  JsonObject toJson() => _$EntityDescriptionToJson(this);
}

@JsonSerializable()
class DatabaseDescription {
  final bool dateTimeAsText;
  final List<EntityDescription> entities;

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

  factory DatabaseDescription.fromJson(JsonObject obj) =>
      _$DatabaseDescriptionFromJson(obj);

  JsonObject toJson() => _$DatabaseDescriptionToJson(this);
}
