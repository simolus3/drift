// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../analysis/options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriftOptions _$DriftOptionsFromJson(Map json) => DriftOptions(
      generateFromJsonStringConstructor:
          json['write_from_json_string_constructor'] as bool? ?? false,
      overrideHashAndEqualsInResultSets:
          json['override_hash_and_equals_in_result_sets'] as bool? ?? false,
      skipVerificationCode: json['skip_verification_code'] as bool? ?? false,
      useDataClassNameForCompanions:
          json['use_data_class_name_for_companions'] as bool? ?? false,
      useColumnNameAsJsonKeyWhenDefinedInMoorFile:
          json['use_column_name_as_json_key_when_defined_in_moor_file']
                  as bool? ??
              true,
      generateConnectConstructor:
          json['generate_connect_constructor'] as bool? ?? false,
      dataClassToCompanions: json['data_class_to_companions'] as bool? ?? true,
      generateMutableClasses: json['mutable_classes'] as bool? ?? false,
      rawResultSetData: json['raw_result_set_data'] as bool? ?? false,
      applyConvertersOnVariables:
          json['apply_converters_on_variables'] as bool? ?? true,
      generateValuesInCopyWith:
          json['generate_values_in_copy_with'] as bool? ?? true,
      generateNamedParameters: json['named_parameters'] as bool? ?? false,
      namedParametersAlwaysRequired:
          json['named_parameters_always_required'] as bool? ?? false,
      scopedDartComponents: json['scoped_dart_components'] as bool? ?? true,
      modules: (json['sqlite_modules'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$SqlModuleEnumMap, e))
              .toList() ??
          [],
      sqliteAnalysisOptions: json['sqlite'] == null
          ? null
          : SqliteAnalysisOptions.fromJson(json['sqlite'] as Map),
      storeDateTimeValuesAsText:
          json['store_date_time_values_as_text'] as bool? ?? false,
      dialect: json['sql'] == null
          ? null
          : DialectOptions.fromJson(json['sql'] as Map),
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
  SqlModule.spellfix1: 'spellfix1',
};

DialectOptions _$DialectOptionsFromJson(Map json) => DialectOptions(
      $enumDecode(_$SqlDialectEnumMap, json['dialect']),
      json['options'] == null
          ? null
          : SqliteAnalysisOptions.fromJson(json['options'] as Map),
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
    SqliteAnalysisOptions(
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$SqlModuleEnumMap, e))
              .toList() ??
          const [],
      version: _$JsonConverterFromJson<String, SqliteVersion>(
          json['version'], const _SqliteVersionConverter().fromJson),
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
