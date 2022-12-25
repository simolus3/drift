// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../analysis/results/result_sets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExistingRowClass _$ExistingRowClassFromJson(Map json) => ExistingRowClass(
      targetClass: AnnotatedDartCode.fromJson(json['target_class'] as Map),
      targetType: AnnotatedDartCode.fromJson(json['target_type'] as Map),
      constructor: json['constructor'] as String,
      positionalColumns: (json['positional_columns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      namedColumns: Map<String, String>.from(json['named_columns'] as Map),
      generateInsertable: json['generate_insertable'] as bool? ?? false,
      isAsyncFactory: json['is_async_factory'] as bool? ?? false,
    );

Map<String, dynamic> _$ExistingRowClassToJson(ExistingRowClass instance) =>
    <String, dynamic>{
      'target_class': instance.targetClass?.toJson(),
      'target_type': instance.targetType.toJson(),
      'constructor': instance.constructor,
      'is_async_factory': instance.isAsyncFactory,
      'positional_columns': instance.positionalColumns,
      'named_columns': instance.namedColumns,
      'generate_insertable': instance.generateInsertable,
    };
