// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoorOptions _$MoorOptionsFromJson(Map json) => $checkedCreate(
      'MoorOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'write_from_json_string_constructor',
            'override_hash_and_equals_in_result_sets',
            'compact_query_methods',
            'skip_verification_code',
            'use_data_class_name_for_companions',
            'use_column_name_as_json_key_when_defined_in_moor_file',
            'generate_connect_constructor',
            'sqlite_modules',
            'sqlite',
            'sql',
            'eagerly_load_dart_ast',
            'data_class_to_companions',
            'mutable_classes',
            'raw_result_set_data',
            'apply_converters_on_variables',
            'generate_values_in_copy_with',
            'named_parameters',
            'named_parameters_always_required',
            'new_sql_code_generation',
            'scoped_dart_components'
          ],
        );
        final val = MoorOptions(
          generateFromJsonStringConstructor: $checkedConvert(
              'write_from_json_string_constructor', (v) => v as bool? ?? false),
          overrideHashAndEqualsInResultSets: $checkedConvert(
              'override_hash_and_equals_in_result_sets',
              (v) => v as bool? ?? false),
          compactQueryMethods: $checkedConvert(
              'compact_query_methods', (v) => v as bool? ?? true),
          skipVerificationCode: $checkedConvert(
              'skip_verification_code', (v) => v as bool? ?? false),
          useDataClassNameForCompanions: $checkedConvert(
              'use_data_class_name_for_companions', (v) => v as bool? ?? false),
          useColumnNameAsJsonKeyWhenDefinedInMoorFile: $checkedConvert(
              'use_column_name_as_json_key_when_defined_in_moor_file',
              (v) => v as bool? ?? true),
          generateConnectConstructor: $checkedConvert(
              'generate_connect_constructor', (v) => v as bool? ?? false),
          eagerlyLoadDartAst: $checkedConvert(
              'eagerly_load_dart_ast', (v) => v as bool? ?? false),
          dataClassToCompanions: $checkedConvert(
              'data_class_to_companions', (v) => v as bool? ?? true),
          generateMutableClasses:
              $checkedConvert('mutable_classes', (v) => v as bool? ?? false),
          rawResultSetData: $checkedConvert(
              'raw_result_set_data', (v) => v as bool? ?? false),
          applyConvertersOnVariables: $checkedConvert(
              'apply_converters_on_variables', (v) => v as bool? ?? false),
          generateValuesInCopyWith: $checkedConvert(
              'generate_values_in_copy_with', (v) => v as bool? ?? false),
          generateNamedParameters:
              $checkedConvert('named_parameters', (v) => v as bool? ?? false),
          namedParametersAlwaysRequired: $checkedConvert(
              'named_parameters_always_required', (v) => v as bool? ?? false),
          newSqlCodeGeneration: $checkedConvert(
              'new_sql_code_generation', (v) => v as bool? ?? false),
          scopedDartComponents: $checkedConvert(
              'scoped_dart_components', (v) => v as bool? ?? false),
          modules: $checkedConvert(
              'sqlite_modules',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) => $enumDecode(_$SqlModuleEnumMap, e))
                      .toList() ??
                  []),
          sqliteAnalysisOptions: $checkedConvert(
              'sqlite',
              (v) =>
                  v == null ? null : SqliteAnalysisOptions.fromJson(v as Map)),
          dialect: $checkedConvert('sql',
              (v) => v == null ? null : DialectOptions.fromJson(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'generateFromJsonStringConstructor':
            'write_from_json_string_constructor',
        'overrideHashAndEqualsInResultSets':
            'override_hash_and_equals_in_result_sets',
        'compactQueryMethods': 'compact_query_methods',
        'skipVerificationCode': 'skip_verification_code',
        'useDataClassNameForCompanions': 'use_data_class_name_for_companions',
        'useColumnNameAsJsonKeyWhenDefinedInMoorFile':
            'use_column_name_as_json_key_when_defined_in_moor_file',
        'generateConnectConstructor': 'generate_connect_constructor',
        'eagerlyLoadDartAst': 'eagerly_load_dart_ast',
        'dataClassToCompanions': 'data_class_to_companions',
        'generateMutableClasses': 'mutable_classes',
        'rawResultSetData': 'raw_result_set_data',
        'applyConvertersOnVariables': 'apply_converters_on_variables',
        'generateValuesInCopyWith': 'generate_values_in_copy_with',
        'generateNamedParameters': 'named_parameters',
        'namedParametersAlwaysRequired': 'named_parameters_always_required',
        'newSqlCodeGeneration': 'new_sql_code_generation',
        'scopedDartComponents': 'scoped_dart_components',
        'modules': 'sqlite_modules',
        'sqliteAnalysisOptions': 'sqlite',
        'dialect': 'sql'
      },
    );

const _$SqlModuleEnumMap = {
  SqlModule.json1: 'json1',
  SqlModule.fts5: 'fts5',
  SqlModule.moor_ffi: 'moor_ffi',
  SqlModule.math: 'math',
};

DialectOptions _$DialectOptionsFromJson(Map json) => $checkedCreate(
      'DialectOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['dialect', 'options'],
        );
        final val = DialectOptions(
          $checkedConvert(
              'dialect', (v) => $enumDecode(_$SqlDialectEnumMap, v)),
          $checkedConvert(
              'options',
              (v) =>
                  v == null ? null : SqliteAnalysisOptions.fromJson(v as Map)),
        );
        return val;
      },
    );

const _$SqlDialectEnumMap = {
  SqlDialect.sqlite: 'sqlite',
  SqlDialect.mysql: 'mysql',
  SqlDialect.postgres: 'postgres',
};

SqliteAnalysisOptions _$SqliteAnalysisOptionsFromJson(Map json) =>
    $checkedCreate(
      'SqliteAnalysisOptions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const ['modules', 'version'],
        );
        final val = SqliteAnalysisOptions(
          modules: $checkedConvert(
              'modules',
              (v) =>
                  (v as List<dynamic>?)
                      ?.map((e) => $enumDecode(_$SqlModuleEnumMap, e))
                      .toList() ??
                  const []),
          version: $checkedConvert(
              'version', (v) => _parseSqliteVersion(v as String?)),
        );
        return val;
      },
    );
