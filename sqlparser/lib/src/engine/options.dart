import 'package:meta/meta.dart';
import 'package:sqlparser/sqlparser.dart';

class EngineOptions {
  /// Moor extends the sql grammar a bit to support type converters and other
  /// features. Enabling this flag will make this engine parse sql with these
  /// extensions enabled.
  final bool useMoorExtensions;

  /// The target sqlite version.
  ///
  /// The library will report when using sqlite features that were added after
  /// the desired [version].
  /// Defaults to [SqliteVersion.current].
  final SqliteVersion version;

  /// All [Extension]s that have been enabled in this sql engine.
  final List<Extension> enabledExtensions;

  final List<FunctionHandler> _addedFunctionHandlers = [];

  /// A map from lowercase function names to the associated handler.
  final Map<String, FunctionHandler> addedFunctions = {};

  /// A map from lowercase function names (where the function is a table-valued
  /// function) to the associated handler.
  final Map<String, TableValuedFunctionHandler> addedTableFunctions = {};

  EngineOptions({
    this.useMoorExtensions = false,
    this.enabledExtensions = const [],
    this.version = SqliteVersion.minimum,
  }) {
    if (version < SqliteVersion.minimum) {
      throw ArgumentError.value(
          version, 'version', 'Must at least be ${SqliteVersion.minimum}');
    }
    if (version > SqliteVersion.current) {
      throw ArgumentError.value(
          version, 'version', 'Must at most be ${SqliteVersion.current}');
    }
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

  /// Version `3.35.0` of `sqlite3`.
  static const SqliteVersion v3_35 = SqliteVersion.v3(35);

  /// The highest sqlite version supported by this `sqlparser` package.
  ///
  /// Newer features in `sqlite3` may not be recognized by this library.
  static const SqliteVersion current = v3_35;

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
