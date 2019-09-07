part of 'moor_builder.dart';

class MoorOptions {
  final bool generateFromJsonStringConstructor;

  /// A bug in the generator generates public watch* methods, even if the query
  /// name starts with an underscore. Fixing this would be a breaking change, so
  /// we introduce a flag that will be the default behavior in the next breaking
  /// moor version.
  final bool fixPrivateWatchMethods;

  MoorOptions(
      this.generateFromJsonStringConstructor, this.fixPrivateWatchMethods);

  factory MoorOptions.fromBuilder(Map<String, dynamic> config) {
    final writeFromString =
        config['write_from_json_string_constructor'] as bool ?? false;
    final fixWatchMethods =
        config['generate_private_watch_methods'] as bool ?? false;

    return MoorOptions(writeFromString, fixWatchMethods);
  }

  const MoorOptions.defaults()
      : generateFromJsonStringConstructor = false,
        fixPrivateWatchMethods = false;
}
