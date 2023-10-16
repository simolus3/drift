// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TypeDescription _$TypeDescriptionFromJson(Map<String, dynamic> json) =>
    TypeDescription(
      type: $enumDecodeNullable(_$DriftSqlTypeEnumMap, json['type']),
      customTypeName: json['customTypeName'] as String?,
    );

Map<String, dynamic> _$TypeDescriptionToJson(TypeDescription instance) =>
    <String, dynamic>{
      'type': _$DriftSqlTypeEnumMap[instance.type],
      'customTypeName': instance.customTypeName,
    };

const _$DriftSqlTypeEnumMap = {
  DriftSqlType.bool: 'bool',
  DriftSqlType.string: 'string',
  DriftSqlType.bigInt: 'bigInt',
  DriftSqlType.int: 'int',
  DriftSqlType.dateTime: 'dateTime',
  DriftSqlType.blob: 'blob',
  DriftSqlType.double: 'double',
  DriftSqlType.any: 'any',
};

ColumnDescription _$ColumnDescriptionFromJson(Map<String, dynamic> json) =>
    ColumnDescription(
      name: json['name'] as String,
      type: json['type'] == null
          ? null
          : TypeDescription.fromJson(json['type'] as Map<String, dynamic>),
      isNullable: json['isNullable'] as bool,
    );

Map<String, dynamic> _$ColumnDescriptionToJson(ColumnDescription instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'isNullable': instance.isNullable,
    };

EntityDescription _$EntityDescriptionFromJson(Map<String, dynamic> json) =>
    EntityDescription(
      name: json['name'] as String,
      type: json['type'] as String,
      columns: (json['columns'] as List<dynamic>?)
          ?.map((e) => ColumnDescription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EntityDescriptionToJson(EntityDescription instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'columns': instance.columns,
    };

DatabaseDescription _$DatabaseDescriptionFromJson(Map<String, dynamic> json) =>
    DatabaseDescription(
      dateTimeAsText: json['dateTimeAsText'] as bool,
      entities: (json['entities'] as List<dynamic>)
          .map((e) => EntityDescription.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DatabaseDescriptionToJson(
        DatabaseDescription instance) =>
    <String, dynamic>{
      'dateTimeAsText': instance.dateTimeAsText,
      'entities': instance.entities,
    };
