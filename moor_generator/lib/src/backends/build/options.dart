part of 'moor_builder.dart';

class MoorOptions {
  final bool generateFromJsonStringConstructor;
  final bool overrideHashAndEqualsInResultSets;

  MoorOptions(this.generateFromJsonStringConstructor,
      this.overrideHashAndEqualsInResultSets);

  factory MoorOptions.fromBuilder(Map<String, dynamic> config) {
    final writeFromString =
        config['write_from_json_string_constructor'] as bool ?? false;

    final overrideInResultSets =
        config['override_hash_and_equals_in_result_sets'] as bool ?? false;

    return MoorOptions(writeFromString, overrideInResultSets);
  }

  const MoorOptions.defaults()
      : generateFromJsonStringConstructor = false,
        overrideHashAndEqualsInResultSets = false;
}
