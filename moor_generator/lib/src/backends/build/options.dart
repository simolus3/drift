part of 'moor_builder.dart';

class MoorOptions {
  final bool generateFromJsonStringConstructor;
  final bool overrideHashAndEqualsInResultSets;
  final bool compactQueryMethods;
  final bool skipVerificationCode;
  final bool useDataClassNameForCompanions;
  final bool useColumnNameAsJsonKeyWhenDefinedInMoorFile;

  const MoorOptions(
      {this.generateFromJsonStringConstructor = false,
      this.overrideHashAndEqualsInResultSets = false,
      this.compactQueryMethods = false,
      this.skipVerificationCode = false,
      this.useDataClassNameForCompanions = false,
      this.useColumnNameAsJsonKeyWhenDefinedInMoorFile = false});

  factory MoorOptions.fromBuilder(Map<String, dynamic> config) {
    final writeFromString =
        config['write_from_json_string_constructor'] as bool ?? false;

    final overrideInResultSets =
        config['override_hash_and_equals_in_result_sets'] as bool ?? false;

    final compactQueryMethods =
        config['compact_query_methods'] as bool ?? false;

    final skipVerificationCode =
        config['skip_verification_code'] as bool ?? false;

    final dataClassNamesForCompanions =
        config['use_data_class_name_for_companions'] as bool ?? false;

    final useColumnNameAsJsonKeyForMoor =
        config['use_column_name_as_json_key_when_defined_in_moor_file']
                as bool ??
            false;

    return MoorOptions(
      generateFromJsonStringConstructor: writeFromString,
      overrideHashAndEqualsInResultSets: overrideInResultSets,
      compactQueryMethods: compactQueryMethods,
      skipVerificationCode: skipVerificationCode,
      useDataClassNameForCompanions: dataClassNamesForCompanions,
      useColumnNameAsJsonKeyWhenDefinedInMoorFile:
          useColumnNameAsJsonKeyForMoor,
    );
  }
}
