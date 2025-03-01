import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

import 'dialect.dart';

part '../generated/analysis/options.g.dart';

/// Controllable options to define the behavior of the analyzer and the
/// generator.
@JsonSerializable()
class DriftOptions {
  /// Whether moor should generate a `fromJsonString` factory for data classes.
  /// It basically wraps the regular `fromJson` constructor in a `json.decode`
  /// call.
  @JsonKey(name: 'write_from_json_string_constructor', defaultValue: false)
  final bool generateFromJsonStringConstructor;

  /// Overrides [Object.hashCode], [Object.==] and [Object.toString] in classes
  /// generated for custom queries.
  ///
  /// The `toString` override was added in a later version, we kept the original
  /// name for backwards compatibility.
  @JsonKey(name: 'override_hash_and_equals_in_result_sets', defaultValue: false)
  final bool overrideHashAndEqualsInResultSets;

  /// Use a `<data-class>Companion` pattern instead of `<table-class>Companion`
  /// when naming companions.
  @JsonKey(name: 'use_data_class_name_for_companions', defaultValue: false)
  final bool useDataClassNameForCompanions;

  /// For a column defined in a moor file, use the name directly instead of
  /// the transformed `camelCaseDartGetter`.
  @JsonKey(
      name: 'use_column_name_as_json_key_when_defined_in_moor_file',
      defaultValue: true)
  final bool useColumnNameAsJsonKeyWhenDefinedInMoorFile;

  /// Uses the sql column name as the json key instead of the name in dart.
  ///
  /// Overrides [useColumnNameAsJsonKeyWhenDefinedInMoorFile] when set to `true`.
  @JsonKey(name: 'use_sql_column_name_as_json_key', defaultValue: false)
  final bool useSqlColumnNameAsJsonKey;

  /// Generate a `connect` constructor in database superclasses.
  ///
  /// This makes drift generate a constructor for database classes that takes a
  /// `DatabaseConnection` instead of just a `QueryExecutor` - meaning that
  /// stream queries can also be shared across multiple database instances.
  /// Starting from drift 2.5, the database connection class implements the
  /// `QueryExecutor` interface, making this option unnecessary.
  @JsonKey(name: 'generate_connect_constructor', defaultValue: false)
  final bool generateConnectConstructor;

  /// Generate managers to assist with common database operations.
  @JsonKey(name: 'generate_manager', defaultValue: true)
  final bool generateManager;

  @JsonKey(name: 'dialects')
  @_DialectsConverter()
  final Map<String, RegisteredDriftDialect> dialects;

  @JsonKey(name: 'data_class_to_companions', defaultValue: true)
  final bool dataClassToCompanions;

  @JsonKey(name: 'mutable_classes', defaultValue: false)
  final bool generateMutableClasses;

  @JsonKey(name: 'row_class_constructor_all_required', defaultValue: false)
  final bool rowClassConstructorAllRequired;

  /// Whether generated query classes should inherit from the `CustomResultSet`
  /// and expose their underlying raw `row`.
  @JsonKey(name: 'raw_result_set_data', defaultValue: false)
  final bool rawResultSetData;

  @JsonKey(name: 'apply_converters_on_variables', defaultValue: true)
  final bool applyConvertersOnVariables;

  @JsonKey(name: 'generate_values_in_copy_with', defaultValue: true)
  final bool generateValuesInCopyWith;

  @JsonKey(name: 'named_parameters', defaultValue: false)
  final bool generateNamedParameters;

  @JsonKey(name: 'named_parameters_always_required', defaultValue: false)
  final bool namedParametersAlwaysRequired;

  @JsonKey(name: 'scoped_dart_components', defaultValue: true)
  final bool scopedDartComponents;

  @JsonKey(name: 'case_from_dart_to_sql', defaultValue: CaseFromDartToSql.snake)
  final CaseFromDartToSql caseFromDartToSql;

  @JsonKey(name: 'write_to_columns_mixins', defaultValue: false)
  final bool writeToColumnsMixins;

  @JsonKey(name: 'assume_correct_reference', defaultValue: false)
  final bool assumeCorrectReference;

  @JsonKey(name: 'has_separate_analyzer', defaultValue: false)
  final bool hasDriftAnalyzer;

  final String? preamble;

  @JsonKey(name: 'fatal_warnings', defaultValue: false)
  final bool fatalWarnings;

  @JsonKey(name: 'schema_dir', defaultValue: "drift_schemas")
  final String schemaDir;

  @JsonKey(name: 'test_dir', defaultValue: "test/drift")
  final String testDir;

  @JsonKey(name: 'databases', defaultValue: {})
  final Map<String, String> databases;

  @internal
  const DriftOptions.defaults({
    this.generateFromJsonStringConstructor = false,
    this.overrideHashAndEqualsInResultSets = false,
    this.useDataClassNameForCompanions = false,
    this.useColumnNameAsJsonKeyWhenDefinedInMoorFile = true,
    this.useSqlColumnNameAsJsonKey = false,
    this.generateConnectConstructor = false,
    this.generateManager = true,
    this.dataClassToCompanions = true,
    this.generateMutableClasses = false,
    this.rowClassConstructorAllRequired = false,
    this.rawResultSetData = false,
    this.applyConvertersOnVariables = true,
    this.generateValuesInCopyWith = true,
    this.generateNamedParameters = false,
    this.namedParametersAlwaysRequired = false,
    this.scopedDartComponents = true,
    this.dialects = const {'sqlite': DriftSqliteDialect()},
    this.caseFromDartToSql = CaseFromDartToSql.snake,
    this.preamble,
    this.writeToColumnsMixins = false,
    this.fatalWarnings = false,
    this.hasDriftAnalyzer = false,
    this.assumeCorrectReference = false,
    this.schemaDir = "drift_schemas",
    this.testDir = "test/drift",
    this.databases = const {},
  });

  DriftOptions({
    required this.generateFromJsonStringConstructor,
    required this.overrideHashAndEqualsInResultSets,
    required this.useDataClassNameForCompanions,
    required this.useColumnNameAsJsonKeyWhenDefinedInMoorFile,
    required this.useSqlColumnNameAsJsonKey,
    required this.generateConnectConstructor,
    required this.generateManager,
    required this.dataClassToCompanions,
    required this.generateMutableClasses,
    required this.rowClassConstructorAllRequired,
    required this.rawResultSetData,
    required this.applyConvertersOnVariables,
    required this.generateValuesInCopyWith,
    required this.generateNamedParameters,
    required this.namedParametersAlwaysRequired,
    required this.scopedDartComponents,
    required this.dialects,
    required this.caseFromDartToSql,
    required this.writeToColumnsMixins,
    required this.fatalWarnings,
    required this.preamble,
    required this.hasDriftAnalyzer,
    required this.assumeCorrectReference,
    required this.schemaDir,
    required this.testDir,
    required this.databases,
  });

  factory DriftOptions.fromJson(Map json) => _$DriftOptionsFromJson(json);

  @JsonKey(includeToJson: false)
  DriftSqliteDialect get sqliteDialect {
    return dialects['sqlite'] as DriftSqliteDialect? ??
        const DriftSqliteDialect();
  }

  Map<String, Object?> toJson() => _$DriftOptionsToJson(this);
}

/// The possible values for the case of the table and column names.
enum CaseFromDartToSql {
  /// Preserves the case of the name as it is in the dart code.
  ///
  /// `myColumn` -> `myColumn`.
  preserve,

  /// Use camelCase.
  ///
  /// `my_column` -> `myColumn`.
  @JsonValue('camelCase')
  camel,

  /// Use CONSTANT_CASE.
  ///
  /// `myColumn` -> `MY_COLUMN`.
  @JsonValue('CONSTANT_CASE')
  constant,

  /// Use snake_case.
  ///
  /// `myColumn` -> `my_column`.
  @JsonValue('snake_case')
  snake,

  /// Use PascalCase.
  ///
  /// `my_column` -> `MyColumn`.
  // ignore: constant_identifier_names
  @JsonValue('PascalCase')
  pascal,

  /// Use lowercase.
  ///
  /// `myColumn` -> `mycolumn`.
  @JsonValue('lowercase')
  lower,

  /// Use UPPERCASE.
  ///
  /// `myColumn` -> `MYCOLUMN`.
  @JsonValue('UPPERCASE')
  upper;

  /// Applies the correct case to the given [name].
  String apply(String name) {
    final reCase = ReCase(name);
    switch (this) {
      case CaseFromDartToSql.preserve:
        return name;
      case CaseFromDartToSql.camel:
        return reCase.camelCase;
      case CaseFromDartToSql.constant:
        return reCase.constantCase;
      case CaseFromDartToSql.snake:
        return reCase.snakeCase;
      case CaseFromDartToSql.pascal:
        return reCase.pascalCase;
      case CaseFromDartToSql.lower:
        return name.toLowerCase();
      case CaseFromDartToSql.upper:
        return name.toUpperCase();
    }
  }
}

final class _DialectsConverter extends JsonConverter<
    Map<String, RegisteredDriftDialect>, Map<Object?, Object?>> {
  const _DialectsConverter();

  @override
  Map<String, RegisteredDriftDialect> fromJson(Map<Object?, Object?> json) {
    return json.cast<String, Object?>().map((k, v) {
      final parsed = switch (k) {
        'sqlite' => DriftSqliteDialect.fromJson(v as Map),
        _ => CustomDriftDialect(k)
      };
      return MapEntry(k, parsed);
    });
  }

  @override
  Map<String, Object?> toJson(Map<String, RegisteredDriftDialect> object) {
    return object.map((k, v) => MapEntry(k, v.toJson()));
  }
}
