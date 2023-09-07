import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart';

class EngineOptions {
  /// If drift extensions are enabled, contains options on how to interpret
  /// drift-specific syntax.
  ///
  /// Drift extends the sql grammar a bit to support type converters and other
  /// features. Enabling this flag will make this engine parse sql with these
  /// extensions enabled.
  final DriftSqlOptions? driftOptions;

  /// The target sqlite version.
  ///
  /// This library will report analysis errors when using features there weren't
  /// available in the targeted [version].
  /// Defaults to [SqliteVersion.minimum].
  final SqliteVersion version;

  /// All [Extension]s that have been enabled in this sql engine.
  final List<Extension> enabledExtensions;

  final List<FunctionHandler> _addedFunctionHandlers = [];

  /// A map from lowercase function names to the associated handler.
  final Map<String, FunctionHandler> addedFunctions = {};

  /// A map from lowercase function names (where the function is a table-valued
  /// function) to the associated handler.
  final Map<String, TableValuedFunctionHandler> addedTableFunctions = {};

  bool get useDriftExtensions => driftOptions != null;

  EngineOptions({
    this.driftOptions,
    List<Extension> enabledExtensions = const [],
    this.version = SqliteVersion.minimum,
  }) : enabledExtensions = _allExtensions(enabledExtensions, version) {
    if (version < SqliteVersion.minimum) {
      throw ArgumentError.value(
          version, 'version', 'Must at least be ${SqliteVersion.minimum}');
    }
    if (version > SqliteVersion.current) {
      throw ArgumentError.value(
          version, 'version', 'Must at most be ${SqliteVersion.current}');
    }
  }

  static List<Extension> _allExtensions(
      List<Extension> added, SqliteVersion version) {
    return [
      // The json1 extension was enabled by default in sqlite3 version 3.38, so
      // add it if it's not already enabled.
      if (version >= SqliteVersion.v3_38 &&
          !added.any((e) => e is Json1Extension))
        const Json1Extension(),
      ...added,
    ];
  }

  void addFunctionHandler(FunctionHandler handler) {
    _addedFunctionHandlers.add(handler);

    for (final function in handler.functionNames) {
      addedFunctions[function.toLowerCase()] = handler;
    }
  }

  void addTableValuedFunctionHandler(TableValuedFunctionHandler handler) {
    addedTableFunctions[handler.functionName.toLowerCase()] = handler;
  }
}

/// Drift-specific parsing and analysis options that are not enabled by default.
class DriftSqlOptions {
  final bool storeDateTimesAsText;

  const DriftSqlOptions({
    this.storeDateTimesAsText = false,
  });
}

/// The assumed version of `sqlite3`.
///
/// This library can provide analysis hints when using sqlite features newer
/// than the desired version.
@sealed
class SqliteVersion implements Comparable<SqliteVersion> {
  /// The minimum sqlite version assumed by the current version of the
  /// `sqlparser` package.
  ///
  /// This does not mean that older version aren't supported, but this library
  /// can't provide analysis warnings when using recent sqlite3 features.
  static const SqliteVersion minimum = SqliteVersion.v3(34);

  /// Version `3.43.0` added the built-in `timediff` and `octet_length`
  /// functions.
  static const SqliteVersion v3_43 = SqliteVersion.v3(43);

  /// Version `3.41.0` added the built-in `unhex` function.
  static const SqliteVersion v3_41 = SqliteVersion.v3(41);

  /// Version `3.39.0` of `sqlite3`.
  ///
  /// New language features include `RIGHT` / `FULL OUTER JOIN` and `IS DISTINCT
  /// FROM`.
  static const SqliteVersion v3_39 = SqliteVersion.v3(39);

  /// Version `3.38.0` of `sqlite3`.
  static const SqliteVersion v3_38 = SqliteVersion.v3(38);

  /// Version `3.37.0` of `sqlite3`.
  static const SqliteVersion v3_37 = SqliteVersion.v3(37);

  /// Version `3.35.0` of `sqlite3`.
  static const SqliteVersion v3_35 = SqliteVersion.v3(35);

  /// The highest sqlite version supported by this `sqlparser` package.
  ///
  /// Newer features in `sqlite3` may not be recognized by this library.
  static const SqliteVersion current = v3_43;

  /// The major version of sqlite.
  ///
  /// This will always be `3` in the foreseeable future.
  final int major;

  /// The minor version of sqlite.
  ///
  /// sqlite version `3.34.0` would have a minor version of `34`.
  final int minor;

  /// The patch version of sqlite.
  ///
  /// sqlite version `3.34.1` would have a minor version of `1`.
  final int patch;

  const SqliteVersion(this.major, this.minor, this.patch);

  const SqliteVersion.v3(int minor, [int patch = 0]) : this(3, minor, patch);

  bool operator <(SqliteVersion other) => compareTo(other) < 0;
  bool operator >(SqliteVersion other) => compareTo(other) > 0;
  bool operator >=(SqliteVersion other) => compareTo(other) >= 0;

  @override
  int compareTo(SqliteVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    return 0;
  }

  @override
  int get hashCode => major * minor * patch;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SqliteVersion &&
            other.major == major &&
            other.minor == minor &&
            other.patch == patch;
  }

  @override
  String toString() {
    return 'SqliteVersion($major, $minor, $patch)';
  }
}
