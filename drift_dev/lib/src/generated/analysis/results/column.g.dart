// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/column.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppliedTypeConverter _$AppliedTypeConverterFromJson(Map json) => $checkedCreate(
      'AppliedTypeConverter',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'expression',
            'dart_type',
            'sql_type',
            'dart_type_is_nullable',
            'sql_type_is_nullable',
            'also_applies_to_json_conversion'
          ],
        );
        final val = AppliedTypeConverter(
          expression: $checkedConvert(
              'expression', (v) => AnnotatedDartCode.fromJson(v as Map)),
          dartType: $checkedConvert(
              'dart_type', (v) => AnnotatedDartCode.fromJson(v as Map)),
          sqlType: $checkedConvert(
              'sql_type', (v) => $enumDecode(_$DriftSqlTypeEnumMap, v)),
          dartTypeIsNullable:
              $checkedConvert('dart_type_is_nullable', (v) => v as bool),
          sqlTypeIsNullable:
              $checkedConvert('sql_type_is_nullable', (v) => v as bool),
          alsoAppliesToJsonConversion: $checkedConvert(
              'also_applies_to_json_conversion', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {
        'dartType': 'dart_type',
        'sqlType': 'sql_type',
        'dartTypeIsNullable': 'dart_type_is_nullable',
        'sqlTypeIsNullable': 'sql_type_is_nullable',
        'alsoAppliesToJsonConversion': 'also_applies_to_json_conversion'
      },
    );

Map<String, dynamic> _$AppliedTypeConverterToJson(
        AppliedTypeConverter instance) =>
    <String, dynamic>{
      'expression': instance.expression.toJson(),
      'dart_type': instance.dartType.toJson(),
      'sql_type': _$DriftSqlTypeEnumMap[instance.sqlType]!,
      'dart_type_is_nullable': instance.dartTypeIsNullable,
      'sql_type_is_nullable': instance.sqlTypeIsNullable,
      'also_applies_to_json_conversion': instance.alsoAppliesToJsonConversion,
    };

const _$DriftSqlTypeEnumMap = {
  DriftSqlType.bool: 'bool',
  DriftSqlType.string: 'string',
  DriftSqlType.bigInt: 'bigInt',
  DriftSqlType.int: 'int',
  DriftSqlType.dateTime: 'dateTime',
  DriftSqlType.blob: 'blob',
  DriftSqlType.double: 'double',
};
