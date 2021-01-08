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
      'sqlite_modules',
      'eagerly_load_dart_ast',
      'data_class_to_companions',
      'mutable_classes',
      'raw_result_set_data',
      'apply_converters_on_variables',
      'generate_values_in_copy_with',
      'named_parameters',
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
              true,
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
          true,
      generateConnectConstructor: $checkedConvert(
              json, 'generate_connect_constructor', (v) => v as bool) ??
          false,
      eagerlyLoadDartAst:
          $checkedConvert(json, 'eagerly_load_dart_ast', (v) => v as bool) ??
              false,
      dataClassToCompanions:
          $checkedConvert(json, 'data_class_to_companions', (v) => v as bool) ??
              true,
      generateMutableClasses:
          $checkedConvert(json, 'mutable_classes', (v) => v as bool) ?? false,
      rawResultSetData:
          $checkedConvert(json, 'raw_result_set_data', (v) => v as bool) ??
              false,
      applyConvertersOnVariables: $checkedConvert(
              json, 'apply_converters_on_variables', (v) => v as bool) ??
          false,
      generateValuesInCopyWith: $checkedConvert(
              json, 'generate_values_in_copy_with', (v) => v as bool) ??
          false,
      generateNamedParameters:
          $checkedConvert(json, 'named_parameters', (v) => v as bool) ?? false,
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
    'eagerlyLoadDartAst': 'eagerly_load_dart_ast',
    'dataClassToCompanions': 'data_class_to_companions',
    'generateMutableClasses': 'mutable_classes',
    'modules': 'sqlite_modules',
    'rawResultSetData': 'raw_result_set_data',
    'generateValuesInCopyWith': 'generate_values_in_copy_with',
    'generateNamedParameters': 'named_parameters',
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
