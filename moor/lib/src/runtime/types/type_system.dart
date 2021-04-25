part of 'sql_types.dart';

/// Manages the set of [SqlType] known to a database. It's also responsible for
/// returning the appropriate sql type for a given dart type.
class SqlTypeSystem {
  /// The mapping types maintained by this type system.
  final List<SqlType> types;

  /// Constructs a [SqlTypeSystem] from the [types].
  @Deprecated('Only the default instance is supported')
  const factory SqlTypeSystem(List<SqlType> types) = SqlTypeSystem._;

  const SqlTypeSystem._(this.types);

  /// Constructs a [SqlTypeSystem] from the default types.
  const SqlTypeSystem.withDefaults()
      : this._(const [
          BoolType(),
          StringType(),
          IntType(),
          DateTimeType(),
          BlobType(),
          RealType(),
        ]);

  /// Constant field of [SqlTypeSystem.withDefaults]. This field exists as a
  /// workaround for an analyzer bug: https://dartbug.com/38658
  ///
  /// Used internally by generated code.
  static const defaultInstance = SqlTypeSystem.withDefaults();

  /// Returns the appropriate sql type for the dart type provided as the
  /// generic parameter.
  @Deprecated('Use mapToVariable or a mapFromSql method instead')
  SqlType<T> forDartType<T>() {
    return types.singleWhere((t) => t is SqlType<T>) as SqlType<T>;
  }

  /// Maps a Dart object to a (possibly simpler) object that can be used as
  /// parameters to raw sql queries.
  Object? mapToVariable(Object? dart) {
    if (dart == null) return null;

    // These need special handling, all other types are a direct mapping
    if (dart is DateTime) return const DateTimeType().mapToSqlVariable(dart);
    if (dart is bool) return const BoolType().mapToSqlVariable(dart);

    return dart;
  }

  /// Maps a Dart object to a SQL constant representing the same value.
  static String mapToSqlConstant(Object? dart) {
    if (dart == null) return 'NULL';

    // todo: Inline and remove types in the next major moor version
    if (dart is bool) {
      return const BoolType().mapToSqlConstant(dart);
    } else if (dart is String) {
      return const StringType().mapToSqlConstant(dart);
    } else if (dart is int) {
      return const IntType().mapToSqlConstant(dart);
    } else if (dart is DateTime) {
      return const DateTimeType().mapToSqlConstant(dart);
    } else if (dart is Uint8List) {
      return const BlobType().mapToSqlConstant(dart);
    } else if (dart is double) {
      return const RealType().mapToSqlConstant(dart);
    }

    throw ArgumentError.value(dart, 'dart',
        'Must be null, bool, String, int, DateTime, Uint8List or double');
  }
}
