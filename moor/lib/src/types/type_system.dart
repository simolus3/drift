import 'package:moor/src/types/sql_types.dart';

/// Manages the set of [SqlType] known to a database. It's also responsible for
/// returning the appropriate sql type for a given dart type.
class SqlTypeSystem {
  /// The mapping types maintained by this type system.
  final List<SqlType> types;

  /// Constructs a [SqlTypeSystem] from the [types].
  const SqlTypeSystem(this.types);

  /// Constructs a [SqlTypeSystem] from the default types.
  const SqlTypeSystem.withDefaults()
      : this(const [
          BoolType(),
          StringType(),
          IntType(),
          DateTimeType(),
          BlobType(),
          RealType(),
        ]);

  /// Returns the appropriate sql type for the dart type provided as the
  /// generic parameter.
  SqlType<T> forDartType<T>() {
    return types.singleWhere((t) => t is SqlType<T>) as SqlType<T>;
  }
}
