// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../analyzer/options.dart';

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
            'skip_verification_code',
            'use_data_class_name_for_companions',
            'use_column_name_as_json_key_when_defined_in_moor_file',
            'generate_connect_constructor',
            'sqlite_modules',
            'sqlite',
            'sql',
            'data_class_to_companions',
            'mutable_classes',
            'raw_result_set_data',
            'apply_converters_on_variables',
            'generate_values_in_copy_with',
            'named_parameters',
            'named_parameters_always_required',
            'scoped_dart_components',
            'store_date_time_values_as_text'
          ],
        );
        final val = DriftOptions(
          generateFromJsonStringConstructor: $checkedConvert(
              'write_from_json_string_constructor', (v) => v as bool? ?? false),
          overrideHashAndEqualsInResultSets: $checkedConvert(
              'override_hash_and_equals_in_result_sets',
              (v) => v as bool? ?? false),
          skipVerificationCode: $checkedConvert(
              'skip_verification_code', (v) => v as bool? ?? false),
          useDataClassNameForCompanions: $checkedConvert(
              'use_data_class_name_for_companions', (v) => v as bool? ?? false),
          useColumnNameAsJsonKeyWhenDefinedInMoorFile: $checkedConvert(
              'use_column_name_as_json_key_when_defined_in_moor_file',
              (v) => v as bool? ?? true),
          generateConnectConstructor: $checkedConvert(
              'generate_connect_constructor', (v) => v as bool? ?? false),
          dataClassToCompanions: $checkedConvert(
              'data_class_to_companions', (v) => v as bool? ?? true),
          generateMutableClasses:
              $checkedConvert('mutable_classes', (v) => v as bool? ?? false),
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
          storeDateTimeValuesAsText: $checkedConvert(
              'store_date_time_values_as_text', (v) => v as bool? ?? false),
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
        'skipVerificationCode': 'skip_verification_code',
        'useDataClassNameForCompanions': 'use_data_class_name_for_companions',
        'useColumnNameAsJsonKeyWhenDefinedInMoorFile':
            'use_column_name_as_json_key_when_defined_in_moor_file',
        'generateConnectConstructor': 'generate_connect_constructor',
        'dataClassToCompanions': 'data_class_to_companions',
        'generateMutableClasses': 'mutable_classes',
        'rawResultSetData': 'raw_result_set_data',
        'applyConvertersOnVariables': 'apply_converters_on_variables',
        'generateValuesInCopyWith': 'generate_values_in_copy_with',
        'generateNamedParameters': 'named_parameters',
        'namedParametersAlwaysRequired': 'named_parameters_always_required',
        'scopedDartComponents': 'scoped_dart_components',
        'modules': 'sqlite_modules',
        'sqliteAnalysisOptions': 'sqlite',
        'storeDateTimeValuesAsText': 'store_date_time_values_as_text',
        'dialect': 'sql'
      },
    );

Map<String, dynamic> _$DriftOptionsToJson(DriftOptions instance) =>
    <String, dynamic>{
      'write_from_json_string_constructor':
          instance.generateFromJsonStringConstructor,
      'override_hash_and_equals_in_result_sets':
          instance.overrideHashAndEqualsInResultSets,
      'skip_verification_code': instance.skipVerificationCode,
      'use_data_class_name_for_companions':
          instance.useDataClassNameForCompanions,
      'use_column_name_as_json_key_when_defined_in_moor_file':
          instance.useColumnNameAsJsonKeyWhenDefinedInMoorFile,
      'generate_connect_constructor': instance.generateConnectConstructor,
      'sqlite_modules':
          instance.modules.map((e) => _$SqlModuleEnumMap[e]!).toList(),
      'sqlite': instance.sqliteAnalysisOptions?.toJson(),
      'sql': instance.dialect?.toJson(),
      'data_class_to_companions': instance.dataClassToCompanions,
      'mutable_classes': instance.generateMutableClasses,
      'raw_result_set_data': instance.rawResultSetData,
      'apply_converters_on_variables': instance.applyConvertersOnVariables,
      'generate_values_in_copy_with': instance.generateValuesInCopyWith,
      'named_parameters': instance.generateNamedParameters,
      'named_parameters_always_required':
          instance.namedParametersAlwaysRequired,
      'scoped_dart_components': instance.scopedDartComponents,
      'store_date_time_values_as_text': instance.storeDateTimeValuesAsText,
    };

const _$SqlModuleEnumMap = {
  SqlModule.json1: 'json1',
  SqlModule.fts5: 'fts5',
  SqlModule.moor_ffi: 'moor_ffi',
  SqlModule.math: 'math',
  SqlModule.rtree: 'rtree',
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

Map<String, dynamic> _$DialectOptionsToJson(DialectOptions instance) =>
    <String, dynamic>{
      'dialect': _$SqlDialectEnumMap[instance.dialect]!,
      'options': instance.options?.toJson(),
    };

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
              'version',
              (v) => _$JsonConverterFromJson<String, SqliteVersion>(
                  v, const _SqliteVersionConverter().fromJson)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SqliteAnalysisOptionsToJson(
        SqliteAnalysisOptions instance) =>
    <String, dynamic>{
      'modules': instance.modules.map((e) => _$SqlModuleEnumMap[e]!).toList(),
      'version': _$JsonConverterToJson<String, SqliteVersion>(
          instance.version, const _SqliteVersionConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
