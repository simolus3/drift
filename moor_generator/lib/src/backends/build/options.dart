part of 'moor_builder.dart';

class MoorOptions {
  final bool generateFromJsonStringConstructor;
  final bool overrideHashAndEqualsInResultSets;
  final bool compactQueryMethods;
  final bool skipVerificationCode;

  MoorOptions(
      this.generateFromJsonStringConstructor,
      this.overrideHashAndEqualsInResultSets,
      this.compactQueryMethods,
      this.skipVerificationCode);

  factory MoorOptions.fromBuilder(Map<String, dynamic> config) {
    final writeFromString =
        config['write_from_json_string_constructor'] as bool ?? false;

    final overrideInResultSets =
        config['override_hash_and_equals_in_result_sets'] as bool ?? false;

    final compactQueryMethods =
        config['compact_query_methods'] as bool ?? false;

    final skipVerificationCode =
        config['skip_verification_code'] as bool ?? false;

    return MoorOptions(writeFromString, overrideInResultSets,
        compactQueryMethods, skipVerificationCode);
  }

  const MoorOptions.defaults()
      : generateFromJsonStringConstructor = false,
        overrideHashAndEqualsInResultSets = false,
        compactQueryMethods = false,
        skipVerificationCode = false;
}
