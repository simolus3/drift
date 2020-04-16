// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoorOptions _$MoorOptionsFromJson(Map<String, dynamic> json) {
  return $checkedNew('MoorOptions', json, () {
    $checkKeys(json, allowedKeys: const [
      'write_from_json_string_constructor',
      'override_hash_and_equals_in_result_sets',
      'compact_query_methods',
      'skip_verification_code',
      'use_data_class_name_for_companions',
      'use_column_name_as_json_key_when_defined_in_moor_file',
      'generate_connect_constructor',
      'legacy_type_inference',
      'sqlite_modules',
      'eagerly_load_dart_ast'
    ]);
    final val = MoorOptions(
      generateFromJsonStringConstructor: $checkedConvert(
              json, 'write_from_json_string_constructor', (v) => v as bool) ??
          false,
      overrideHashAndEqualsInResultSets: $checkedConvert(json,
              'override_hash_and_equals_in_result_sets', (v) => v as bool) ??
          false,
      compactQueryMethods:
          $checkedConvert(json, 'compact_query_methods', (v) => v as bool) ??
              false,
      skipVerificationCode:
          $checkedConvert(json, 'skip_verification_code', (v) => v as bool) ??
              false,
      useDataClassNameForCompanions: $checkedConvert(
              json, 'use_data_class_name_for_companions', (v) => v as bool) ??
          false,
      useColumnNameAsJsonKeyWhenDefinedInMoorFile: $checkedConvert(
              json,
              'use_column_name_as_json_key_when_defined_in_moor_file',
              (v) => v as bool) ??
          false,
      generateConnectConstructor: $checkedConvert(
              json, 'generate_connect_constructor', (v) => v as bool) ??
          false,
      legacyTypeInference:
          $checkedConvert(json, 'legacy_type_inference', (v) => v as bool) ??
              false,
      eagerlyLoadDartAst:
          $checkedConvert(json, 'eagerly_load_dart_ast', (v) => v as bool) ??
              false,
      modules: $checkedConvert(
              json,
              'sqlite_modules',
              (v) => (v as List)
                  ?.map((e) => _$enumDecodeNullable(_$SqlModuleEnumMap, e))
                  ?.toList()) ??
          [],
    );
    return val;
  }, fieldKeyMap: const {
    'generateFromJsonStringConstructor': 'write_from_json_string_constructor',
    'overrideHashAndEqualsInResultSets':
        'override_hash_and_equals_in_result_sets',
    'compactQueryMethods': 'compact_query_methods',
    'skipVerificationCode': 'skip_verification_code',
    'useDataClassNameForCompanions': 'use_data_class_name_for_companions',
    'useColumnNameAsJsonKeyWhenDefinedInMoorFile':
        'use_column_name_as_json_key_when_defined_in_moor_file',
    'generateConnectConstructor': 'generate_connect_constructor',
    'useExperimentalInference': 'use_experimental_inference',
    'eagerlyLoadDartAst': 'eagerly_load_dart_ast',
    'modules': 'sqlite_modules'
  });
}

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$SqlModuleEnumMap = {
  SqlModule.json1: 'json1',
  SqlModule.fts5: 'fts5',
  SqlModule.moor_ffi: 'moor_ffi',
};
