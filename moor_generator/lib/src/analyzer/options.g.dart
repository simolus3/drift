// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoorOptions _$MoorOptionsFromJson(Map<String, dynamic> json) {
  return $checkedNew('MoorOptions', json, () {
    $checkKeys(json, allowedKeys: const [
      'generate_from_json_string_constructor',
      'override_hash_and_equals_in_result_sets',
      'compact_query_methods',
      'skip_verification_code',
      'use_data_class_name_for_companions',
      'use_column_name_as_json_key_when_defined_in_moor_file',
      'generate_connect_constructor'
    ]);
    final val = MoorOptions(
      generateFromJsonStringConstructor: $checkedConvert(
          json, 'generate_from_json_string_constructor', (v) => v as bool),
      overrideHashAndEqualsInResultSets: $checkedConvert(
          json, 'override_hash_and_equals_in_result_sets', (v) => v as bool),
      compactQueryMethods:
          $checkedConvert(json, 'compact_query_methods', (v) => v as bool),
      skipVerificationCode:
          $checkedConvert(json, 'skip_verification_code', (v) => v as bool),
      useDataClassNameForCompanions: $checkedConvert(
          json, 'use_data_class_name_for_companions', (v) => v as bool),
      useColumnNameAsJsonKeyWhenDefinedInMoorFile: $checkedConvert(
          json,
          'use_column_name_as_json_key_when_defined_in_moor_file',
          (v) => v as bool),
      generateConnectConstructor: $checkedConvert(
          json, 'generate_connect_constructor', (v) => v as bool),
    );
    return val;
  }, fieldKeyMap: const {
    'generateFromJsonStringConstructor':
        'generate_from_json_string_constructor',
    'overrideHashAndEqualsInResultSets':
        'override_hash_and_equals_in_result_sets',
    'compactQueryMethods': 'compact_query_methods',
    'skipVerificationCode': 'skip_verification_code',
    'useDataClassNameForCompanions': 'use_data_class_name_for_companions',
    'useColumnNameAsJsonKeyWhenDefinedInMoorFile':
        'use_column_name_as_json_key_when_defined_in_moor_file',
    'generateConnectConstructor': 'generate_connect_constructor'
  });
}
