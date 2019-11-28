import 'package:json_annotation/json_annotation.dart';

part 'options.g.dart';

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
  @JsonKey(name: 'write_from_json_string_constructor')
  final bool generateFromJsonStringConstructor;

  /// Overrides [Object.hashCode] and [Object.==] in classes generated for
  /// custom queries.
  @JsonKey(name: 'override_hash_and_equals_in_result_sets')
  final bool overrideHashAndEqualsInResultSets;

  /// Also enable the compact query methods from moor files on queries defined
  /// in a `UseMoor` annotation. Compact queries return a `Selectable` instead
  /// of generating two methods (with one returning a stream and another
  /// returning a future)
  @JsonKey(name: 'compact_query_methods')
  final bool compactQueryMethods;

  /// Remove verification logic in the generated code.
  @JsonKey(name: 'skip_verification_code')
  final bool skipVerificationCode;

  /// Use a `<data-class>Companion` pattern instead of `<table-class>Companion`
  /// when naming companions.
  @JsonKey(name: 'use_data_class_name_for_companions')
  final bool useDataClassNameForCompanions;

  /// For a column defined in a moor file, use the name directly instead of
  /// the transformed `camelCaseDartGetter`.
  @JsonKey(name: 'use_column_name_as_json_key_when_defined_in_moor_file')
  final bool useColumnNameAsJsonKeyWhenDefinedInMoorFile;

  /// Generate a `connect` constructor in database superclasses. This is
  /// required to run databases in a background isolate.
  @JsonKey(name: 'generate_connect_constructor')
  final bool generateConnectConstructor;

  const MoorOptions(
      {this.generateFromJsonStringConstructor = false,
      this.overrideHashAndEqualsInResultSets = false,
      this.compactQueryMethods = false,
      this.skipVerificationCode = false,
      this.useDataClassNameForCompanions = false,
      this.useColumnNameAsJsonKeyWhenDefinedInMoorFile = false,
      this.generateConnectConstructor = false});

  factory MoorOptions.fromJson(Map<String, dynamic> json) =>
      _$MoorOptionsFromJson(json);
}
