import 'package:drift/drift.dart' show SqlDialect;
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart' show SqliteVersion;

part '../generated/analyzer/options.g.dart';

/// Controllable options to define the behavior of the analyzer and the
/// generator.
@JsonSerializable()
class DriftOptions {
  static const _defaultSqliteVersion = SqliteVersion.v3(34);

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
      defaultValue: true)
  final bool useColumnNameAsJsonKeyWhenDefinedInMoorFile;

  /// Generate a `connect` constructor in database superclasses. This is
  /// required to run databases in a background isolate.
  @JsonKey(name: 'generate_connect_constructor', defaultValue: false)
  final bool generateConnectConstructor;

  @JsonKey(name: 'sqlite_modules', defaultValue: [])
  @Deprecated('Use effectiveModules instead')
  final List<SqlModule> modules;

  @JsonKey(name: 'sqlite')
  final SqliteAnalysisOptions? sqliteAnalysisOptions;

  @JsonKey(name: 'sql')
  final DialectOptions? dialect;

  @JsonKey(name: 'data_class_to_companions', defaultValue: true)
  final bool dataClassToCompanions;

  @JsonKey(name: 'mutable_classes', defaultValue: false)
  final bool generateMutableClasses;

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

  /// Whether `DateTime` columns should be stored as text (via
  /// [DateTime.toIso8601String]) instead of integers (unix timestamp).
  @JsonKey(defaultValue: false)
  final bool storeDateTimeValuesAsText;

  @internal
  const DriftOptions.defaults({
    this.generateFromJsonStringConstructor = false,
    this.overrideHashAndEqualsInResultSets = false,
    this.skipVerificationCode = false,
    this.useDataClassNameForCompanions = false,
    this.useColumnNameAsJsonKeyWhenDefinedInMoorFile = true,
    this.generateConnectConstructor = false,
    this.dataClassToCompanions = true,
    this.generateMutableClasses = false,
    this.rawResultSetData = false,
    this.applyConvertersOnVariables = true,
    this.generateValuesInCopyWith = true,
    this.generateNamedParameters = false,
    this.namedParametersAlwaysRequired = false,
    this.scopedDartComponents = true,
    this.modules = const [],
    this.sqliteAnalysisOptions,
    this.storeDateTimeValuesAsText = false,
    this.dialect = const DialectOptions(SqlDialect.sqlite, null),
  });

  DriftOptions({
    required this.generateFromJsonStringConstructor,
    required this.overrideHashAndEqualsInResultSets,
    required this.skipVerificationCode,
    required this.useDataClassNameForCompanions,
    required this.useColumnNameAsJsonKeyWhenDefinedInMoorFile,
    required this.generateConnectConstructor,
    required this.dataClassToCompanions,
    required this.generateMutableClasses,
    required this.rawResultSetData,
    required this.applyConvertersOnVariables,
    required this.generateValuesInCopyWith,
    required this.generateNamedParameters,
    required this.namedParametersAlwaysRequired,
    required this.scopedDartComponents,
    required this.modules,
    required this.sqliteAnalysisOptions,
    required this.storeDateTimeValuesAsText,
    this.dialect,
  }) {
    // ignore: deprecated_member_use_from_same_package
    if (sqliteAnalysisOptions != null && modules.isNotEmpty) {
      throw ArgumentError.value(
        // ignore: deprecated_member_use_from_same_package
        modules,
        'modules',
        'May not be set when sqlite options are present. \n'
            'Try moving modules into the sqlite block.',
      );
    }

    if (dialect != null && sqliteAnalysisOptions != null) {
      throw ArgumentError.value(
        sqliteAnalysisOptions,
        'sqlite',
        'The sqlite field cannot be used together the `sql` option. '
            'Try moving it to `sql.options`.',
      );
    }
  }

  factory DriftOptions.fromJson(Map json) => _$DriftOptionsFromJson(json);

  SqliteAnalysisOptions? get sqliteOptions {
    return dialect?.options ?? sqliteAnalysisOptions;
  }

  /// All enabled sqlite modules from these options.
  List<SqlModule> get effectiveModules {
    // ignore: deprecated_member_use_from_same_package
    return sqliteOptions?.modules ?? modules;
  }

  /// Whether the [module] has been enabled in this configuration.
  bool hasModule(SqlModule module) => effectiveModules.contains(module);

  /// Checks whether a deprecated option is enabled.
  ///
  /// At this time, all deprecated options have been removed, meaning that this
  /// getter always returns `false`.
  bool get enabledDeprecatedOption => false;

  SqlDialect get effectiveDialect => dialect?.dialect ?? SqlDialect.sqlite;

  /// The assumed sqlite version used when analyzing queries.
  SqliteVersion get sqliteVersion {
    return sqliteOptions?.version ?? _defaultSqliteVersion;
  }

  Map<String, Object?> toJson() => _$DriftOptionsToJson(this);
}

@JsonSerializable()
class DialectOptions {
  final SqlDialect dialect;
  final SqliteAnalysisOptions? options;

  const DialectOptions(this.dialect, this.options);

  factory DialectOptions.fromJson(Map json) => _$DialectOptionsFromJson(json);

  Map<String, Object?> toJson() => _$DialectOptionsToJson(this);
}

@JsonSerializable()
class SqliteAnalysisOptions {
  @JsonKey(name: 'modules')
  final List<SqlModule> modules;

  @_SqliteVersionConverter()
  final SqliteVersion? version;

  const SqliteAnalysisOptions({this.modules = const [], this.version});

  factory SqliteAnalysisOptions.fromJson(Map json) {
    return _$SqliteAnalysisOptionsFromJson(json);
  }

  Map<String, Object?> toJson() => _$SqliteAnalysisOptionsToJson(this);
}

class _SqliteVersionConverter extends JsonConverter<SqliteVersion, String> {
  static final _versionRegex = RegExp(r'(\d+)\.(\d+)');

  const _SqliteVersionConverter();

  @override
  SqliteVersion fromJson(String json) {
    final match = _versionRegex.firstMatch(json);
    if (match == null) {
      throw ArgumentError.value(
        json,
        'json',
        'Not a valid sqlite version: Expected format major.minor (e.g. 3.34)',
      );
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);

    final version = SqliteVersion(major, minor, 0);
    if (version < SqliteVersion.minimum) {
      throw ArgumentError.value(
        json,
        'json',
        'Version is not supported for analysis (minimum is '
            '${SqliteVersion.minimum}).',
      );
    } else if (version > SqliteVersion.current) {
      throw ArgumentError.value(
        json,
        'json',
        'Version is not supported for analysis (current maximum is '
            '${SqliteVersion.current}).',
      );
    }

    return version;
  }

  @override
  String toJson(SqliteVersion object) {
    return '${object.major}.${object.minor}';
  }
}

/// Set of sqlite modules that require special knowledge from the generator.
enum SqlModule {
  /// Enables support for the json1 module and its functions when parsing sql
  /// queries.
  json1,

  /// Enables support for the fts5 module and its functions when parsing sql
  /// queries.
  fts5,

  /// Enables support for mathematical functions only available in `moor_ffi`.
  // note: We're ignoring the warning because we can't change the json key
  // ignore: constant_identifier_names
  moor_ffi,

  /// Enables support for [built in math functions][math funs] when analysing
  /// sql queries.
  ///
  /// [math funs]: https://www.sqlite.org/lang_mathfunc.html
  math,

  /// Enables support for the rtree module and its functions when parsing sql
  /// queries.
  rtree,

  spellfix1,
}
