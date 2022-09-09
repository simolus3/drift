// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/result_sets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExistingRowClass _$ExistingRowClassFromJson(Map json) => $checkedCreate(
      'ExistingRowClass',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'target_class',
            'target_type',
            'constructor',
            'is_async_factory',
            'positional_columns',
            'named_columns',
            'generate_insertable'
          ],
        );
        final val = ExistingRowClass(
          targetClass: $checkedConvert(
              'target_class', (v) => AnnotatedDartCode.fromJson(v as Map)),
          targetType: $checkedConvert(
              'target_type', (v) => AnnotatedDartCode.fromJson(v as Map)),
          constructor: $checkedConvert('constructor', (v) => v as String),
          positionalColumns: $checkedConvert('positional_columns',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          namedColumns: $checkedConvert(
              'named_columns', (v) => Map<String, String>.from(v as Map)),
          generateInsertable: $checkedConvert(
              'generate_insertable', (v) => v as bool? ?? false),
          isAsyncFactory:
              $checkedConvert('is_async_factory', (v) => v as bool? ?? false),
        );
        return val;
      },
      fieldKeyMap: const {
        'targetClass': 'target_class',
        'targetType': 'target_type',
        'positionalColumns': 'positional_columns',
        'namedColumns': 'named_columns',
        'generateInsertable': 'generate_insertable',
        'isAsyncFactory': 'is_async_factory'
      },
    );

Map<String, dynamic> _$ExistingRowClassToJson(ExistingRowClass instance) =>
    <String, dynamic>{
      'target_class': instance.targetClass.toJson(),
      'target_type': instance.targetType.toJson(),
      'constructor': instance.constructor,
      'is_async_factory': instance.isAsyncFactory,
      'positional_columns': instance.positionalColumns,
      'named_columns': instance.namedColumns,
      'generate_insertable': instance.generateInsertable,
    };
