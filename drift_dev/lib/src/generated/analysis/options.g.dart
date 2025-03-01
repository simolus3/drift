// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../analysis/options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftOptions _$DriftOptionsFromJson(Map json) => $checkedCreate(
      'DriftOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'write_from_json_string_constructor',
            'override_hash_and_equals_in_result_sets',
            'use_data_class_name_for_companions',
            'use_column_name_as_json_key_when_defined_in_moor_file',
            'use_sql_column_name_as_json_key',
            'generate_connect_constructor',
            'generate_manager',
            'dialects',
            'data_class_to_companions',
            'mutable_classes',
            'row_class_constructor_all_required',
            'raw_result_set_data',
            'apply_converters_on_variables',
            'generate_values_in_copy_with',
            'named_parameters',
            'named_parameters_always_required',
            'scoped_dart_components',
            'case_from_dart_to_sql',
            'write_to_columns_mixins',
            'assume_correct_reference',
            'has_separate_analyzer',
            'preamble',
            'fatal_warnings',
            'schema_dir',
            'test_dir',
            'databases'
          ],
        );
        final val = DriftOptions(
          generateFromJsonStringConstructor: $checkedConvert(
              'write_from_json_string_constructor', (v) => v as bool? ?? false),
          overrideHashAndEqualsInResultSets: $checkedConvert(
              'override_hash_and_equals_in_result_sets',
              (v) => v as bool? ?? false),
          useDataClassNameForCompanions: $checkedConvert(
              'use_data_class_name_for_companions', (v) => v as bool? ?? false),
          useColumnNameAsJsonKeyWhenDefinedInMoorFile: $checkedConvert(
              'use_column_name_as_json_key_when_defined_in_moor_file',
              (v) => v as bool? ?? true),
          useSqlColumnNameAsJsonKey: $checkedConvert(
              'use_sql_column_name_as_json_key', (v) => v as bool? ?? false),
          generateConnectConstructor: $checkedConvert(
              'generate_connect_constructor', (v) => v as bool? ?? false),
          generateManager:
              $checkedConvert('generate_manager', (v) => v as bool? ?? true),
          dataClassToCompanions: $checkedConvert(
              'data_class_to_companions', (v) => v as bool? ?? true),
          generateMutableClasses:
              $checkedConvert('mutable_classes', (v) => v as bool? ?? false),
          rowClassConstructorAllRequired: $checkedConvert(
              'row_class_constructor_all_required', (v) => v as bool? ?? false),
          rawResultSetData: $checkedConvert(
              'raw_result_set_data', (v) => v as bool? ?? false),
          applyConvertersOnVariables: $checkedConvert(
              'apply_converters_on_variables', (v) => v as bool? ?? true),
          generateValuesInCopyWith: $checkedConvert(
              'generate_values_in_copy_with', (v) => v as bool? ?? true),
          generateNamedParameters:
              $checkedConvert('named_parameters', (v) => v as bool? ?? false),
          namedParametersAlwaysRequired: $checkedConvert(
              'named_parameters_always_required', (v) => v as bool? ?? false),
          scopedDartComponents: $checkedConvert(
              'scoped_dart_components', (v) => v as bool? ?? true),
          dialects: $checkedConvert(
              'dialects', (v) => const _DialectsConverter().fromJson(v as Map)),
          caseFromDartToSql: $checkedConvert(
              'case_from_dart_to_sql',
              (v) =>
                  $enumDecodeNullable(_$CaseFromDartToSqlEnumMap, v) ??
                  CaseFromDartToSql.snake),
          writeToColumnsMixins: $checkedConvert(
              'write_to_columns_mixins', (v) => v as bool? ?? false),
          fatalWarnings:
              $checkedConvert('fatal_warnings', (v) => v as bool? ?? false),
          preamble: $checkedConvert('preamble', (v) => v as String?),
          hasDriftAnalyzer: $checkedConvert(
              'has_separate_analyzer', (v) => v as bool? ?? false),
          assumeCorrectReference: $checkedConvert(
              'assume_correct_reference', (v) => v as bool? ?? false),
          schemaDir: $checkedConvert(
              'schema_dir', (v) => v as String? ?? 'drift_schemas'),
          testDir:
              $checkedConvert('test_dir', (v) => v as String? ?? 'test/drift'),
          databases: $checkedConvert(
              'databases',
              (v) =>
                  (v as Map?)?.map(
                    (k, e) => MapEntry(k as String, e as String),
                  ) ??
                  {}),
        );
        return val;
      },
      fieldKeyMap: const {
        'generateFromJsonStringConstructor':
            'write_from_json_string_constructor',
        'overrideHashAndEqualsInResultSets':
            'override_hash_and_equals_in_result_sets',
        'useDataClassNameForCompanions': 'use_data_class_name_for_companions',
        'useColumnNameAsJsonKeyWhenDefinedInMoorFile':
            'use_column_name_as_json_key_when_defined_in_moor_file',
        'useSqlColumnNameAsJsonKey': 'use_sql_column_name_as_json_key',
        'generateConnectConstructor': 'generate_connect_constructor',
        'generateManager': 'generate_manager',
        'dataClassToCompanions': 'data_class_to_companions',
        'generateMutableClasses': 'mutable_classes',
        'rowClassConstructorAllRequired': 'row_class_constructor_all_required',
        'rawResultSetData': 'raw_result_set_data',
        'applyConvertersOnVariables': 'apply_converters_on_variables',
        'generateValuesInCopyWith': 'generate_values_in_copy_with',
        'generateNamedParameters': 'named_parameters',
        'namedParametersAlwaysRequired': 'named_parameters_always_required',
        'scopedDartComponents': 'scoped_dart_components',
        'caseFromDartToSql': 'case_from_dart_to_sql',
        'writeToColumnsMixins': 'write_to_columns_mixins',
        'fatalWarnings': 'fatal_warnings',
        'hasDriftAnalyzer': 'has_separate_analyzer',
        'assumeCorrectReference': 'assume_correct_reference',
        'schemaDir': 'schema_dir',
        'testDir': 'test_dir'
      },
    );

Map<String, dynamic> _$DriftOptionsToJson(DriftOptions instance) =>
    <String, dynamic>{
      'write_from_json_string_constructor':
          instance.generateFromJsonStringConstructor,
      'override_hash_and_equals_in_result_sets':
          instance.overrideHashAndEqualsInResultSets,
      'use_data_class_name_for_companions':
          instance.useDataClassNameForCompanions,
      'use_column_name_as_json_key_when_defined_in_moor_file':
          instance.useColumnNameAsJsonKeyWhenDefinedInMoorFile,
      'use_sql_column_name_as_json_key': instance.useSqlColumnNameAsJsonKey,
      'generate_connect_constructor': instance.generateConnectConstructor,
      'generate_manager': instance.generateManager,
      'dialects': const _DialectsConverter().toJson(instance.dialects),
      'data_class_to_companions': instance.dataClassToCompanions,
      'mutable_classes': instance.generateMutableClasses,
      'row_class_constructor_all_required':
          instance.rowClassConstructorAllRequired,
      'raw_result_set_data': instance.rawResultSetData,
      'apply_converters_on_variables': instance.applyConvertersOnVariables,
      'generate_values_in_copy_with': instance.generateValuesInCopyWith,
      'named_parameters': instance.generateNamedParameters,
      'named_parameters_always_required':
          instance.namedParametersAlwaysRequired,
      'scoped_dart_components': instance.scopedDartComponents,
      'case_from_dart_to_sql':
          _$CaseFromDartToSqlEnumMap[instance.caseFromDartToSql]!,
      'write_to_columns_mixins': instance.writeToColumnsMixins,
      'assume_correct_reference': instance.assumeCorrectReference,
      'has_separate_analyzer': instance.hasDriftAnalyzer,
      'preamble': instance.preamble,
      'fatal_warnings': instance.fatalWarnings,
      'schema_dir': instance.schemaDir,
      'test_dir': instance.testDir,
      'databases': instance.databases,
    };

const _$CaseFromDartToSqlEnumMap = {
  CaseFromDartToSql.preserve: 'preserve',
  CaseFromDartToSql.camel: 'camelCase',
  CaseFromDartToSql.constant: 'CONSTANT_CASE',
  CaseFromDartToSql.snake: 'snake_case',
  CaseFromDartToSql.pascal: 'PascalCase',
  CaseFromDartToSql.lower: 'lowercase',
  CaseFromDartToSql.upper: 'UPPERCASE',
};
