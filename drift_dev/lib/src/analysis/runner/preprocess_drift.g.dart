// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preprocess_drift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftPreprocessorResult _$DriftPreprocessorResultFromJson(Map json) =>
    $checkedCreate(
      'DriftPreprocessorResult',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'inline_dart_expressions_to_helper_field',
            'declared_tables_and_views',
            'imports'
          ],
        );
        final val = DriftPreprocessorResult._(
          $checkedConvert('inline_dart_expressions_to_helper_field',
              (v) => Map<String, String>.from(v as Map)),
          $checkedConvert('declared_tables_and_views',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          $checkedConvert(
              'imports',
              (v) => (v as List<dynamic>)
                  .map((e) => Uri.parse(e as String))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'inlineDartExpressionsToHelperField':
            'inline_dart_expressions_to_helper_field',
        'declaredTablesAndViews': 'declared_tables_and_views'
      },
    );

Map<String, dynamic> _$DriftPreprocessorResultToJson(
        DriftPreprocessorResult instance) =>
    <String, dynamic>{
      'inline_dart_expressions_to_helper_field':
          instance.inlineDartExpressionsToHelperField,
      'declared_tables_and_views': instance.declaredTablesAndViews,
      'imports': instance.imports.map((e) => e.toString()).toList(),
    };
