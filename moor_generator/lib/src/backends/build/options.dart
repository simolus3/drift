part of 'moor_builder.dart';

class MoorOptions {
  final bool generateFromJsonStringConstructor;

  MoorOptions(this.generateFromJsonStringConstructor);

  factory MoorOptions.fromBuilder(Map<String, dynamic> config) {
    final writeFromString =
        config['write_from_json_string_constructor'] as bool ?? false;

    return MoorOptions(writeFromString);
  }

  const MoorOptions.defaults() : generateFromJsonStringConstructor = false;
}
