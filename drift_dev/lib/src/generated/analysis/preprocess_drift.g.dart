// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../analysis/preprocess_drift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftPreprocessorResult _$DriftPreprocessorResultFromJson(Map json) =>
    DriftPreprocessorResult._(
      Map<String, String>.from(
          json['inline_dart_expressions_to_helper_field'] as Map),
      (json['declared_tables_and_views'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      (json['imports'] as List<dynamic>)
          .map((e) => Uri.parse(e as String))
          .toList(),
    );

Map<String, dynamic> _$DriftPreprocessorResultToJson(
        DriftPreprocessorResult instance) =>
    <String, dynamic>{
      'inline_dart_expressions_to_helper_field':
          instance.inlineDartExpressionsToHelperField,
      'declared_tables_and_views': instance.declaredTablesAndViews,
      'imports': instance.imports.map((e) => e.toString()).toList(),
    };
