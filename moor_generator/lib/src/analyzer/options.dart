import 'package:json_annotation/json_annotation.dart';

part 'options.g.dart';

// note when working on this file: If you can't run the builder because
// options.g.dart is missing, just re-create it from git. build_runner will
// complain about existing outputs, let it delete the part file.

/// Controllable options to define the behavior of the analyzer and the
/// generator.
@JsonSerializable(
  checked: true,
  disallowUnrecognizedKeys: true,
  fieldRename: FieldRename.snake,
  createToJson: false,
)
class MoorOptions {
  /// Whether moor should generate a `fromJsonString` factory for data classes.
  /// It basically wraps the regular `fromJson` constructor in a `json.decode`
  /// call.
  @JsonKey(name: 'write_from_json_string_constructor', defaultValue: false)
  final bool generateFromJsonStringConstructor;

  /// Overrides [Object.hashCode] and [Object.==] in classes generated for
  /// custom queries.
  @JsonKey(name: 'override_hash_and_equals_in_result_sets', defaultValue: false)
  final bool overrideHashAndEqualsInResultSets;

  /// Also enable the compact query methods from moor files on queries defined
  /// in a `UseMoor` annotation. Compact queries return a `Selectable` instead
  /// of generating two methods (with one returning a stream and another
  /// returning a future)
  @JsonKey(name: 'compact_query_methods', defaultValue: false)
  final bool compactQueryMethods;

  /// Remove verification logic in the generated code.
  @JsonKey(name: 'skip_verification_code', defaultValue: false)
  final bool skipVerificationCode;

  /// Use a `<data-class>Companion` pattern instead of `<table-class>Companion`
  /// when naming companions.
  @JsonKey(name: 'use_data_class_name_for_companions', defaultValue: false)
  final bool useDataClassNameForCompanions;

  /// For a column defined in a moor file, use the name directly instead of
  /// the transformed `camelCaseDartGetter`.
  @JsonKey(
      name: 'use_column_name_as_json_key_when_defined_in_moor_file',
      defaultValue: false)
  final bool useColumnNameAsJsonKeyWhenDefinedInMoorFile;

  /// Generate a `connect` constructor in database superclasses. This is
  /// required to run databases in a background isolate.
  @JsonKey(name: 'generate_connect_constructor', defaultValue: false)
  final bool generateConnectConstructor;

  @JsonKey(name: 'sqlite_modules', defaultValue: [])
  final List<SqlModule> modules;

  /// Whether the [module] has been enabled in this configuration.
  bool hasModule(SqlModule module) => modules.contains(module);

  const MoorOptions(
      {this.generateFromJsonStringConstructor = false,
      this.overrideHashAndEqualsInResultSets = false,
      this.compactQueryMethods = false,
      this.skipVerificationCode = false,
      this.useDataClassNameForCompanions = false,
      this.useColumnNameAsJsonKeyWhenDefinedInMoorFile = false,
      this.generateConnectConstructor = false,
      this.modules = const []});

  factory MoorOptions.fromJson(Map<String, dynamic> json) =>
      _$MoorOptionsFromJson(json);
}

/// Set of sqlite modules that require special knowledge from the generator.
enum SqlModule {
  /// Enables support for the json1 module and its functions when parsing sql
  /// queries.
  json1,

  /// Enables support for the fts5 module and its functions when parsing sql
  /// queries.
  fts5,
}
