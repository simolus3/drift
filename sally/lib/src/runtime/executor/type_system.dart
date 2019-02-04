import 'package:sally/src/runtime/sql_types.dart';

class SqlTypeSystem {
  final List<SqlType> types;

  const SqlTypeSystem(this.types);

  const SqlTypeSystem.withDefaults()
      : this(const [BoolType(), StringType(), IntType()]);

  /// Returns the appropriate sql type for the dart type provided as the
  /// generic parameter.
  SqlType<T> forDartType<T>() {
    return types.singleWhere((t) => t is SqlType<T>) as SqlType<T>;
  }
}
