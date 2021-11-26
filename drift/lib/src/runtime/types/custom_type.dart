part of 'sql_types.dart';

/// Maps a custom dart object of type [D] into a primitive type [S] understood
/// by the sqlite backend.
///
/// Dart currently supports [DateTime], [double], [int], [Uint8List], [bool]
/// and [String] for [S].
///
/// Also see [BuildColumn.map] for details.
abstract class TypeConverter<D, S> {
  /// Empty constant constructor so that subclasses can have a constant
  /// constructor.
  const TypeConverter();

  /// Map a value from an object in Dart into something that will be understood
  /// by the database.
  S mapToSql(D value);

  /// Maps a column from the database back to Dart.
  D mapToDart(S fromDb);
}

/// Implementation for an enum to int converter that uses the index of the enum
/// as the value stored in the database.
class EnumIndexConverter<T> extends TypeConverter<T, int> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const EnumIndexConverter(this.values);

  @override
  T mapToDart(int fromDb) {
    return values[fromDb];
  }

  @override
  int mapToSql(T value) {
    // In Dart 2.14: Cast to Enum instead of dynamic. Also add Enum as an upper
    // bound for T.
    return (value as dynamic).index as int;
  }
}

/// Implementation for a nullable enum to int converter that uses the index of
/// the enum as the value stored in the database.
class NullableEnumIndexConverter<T> extends TypeConverter<T?, int?> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const NullableEnumIndexConverter(this.values);

  @override
  T? mapToDart(int? fromDb) {
    return fromDb == null ? null : values[fromDb];
  }

  @override
  int? mapToSql(T? value) {
    // In Dart 2.14: Cast to Enum instead of dynamic. Also add Enum as an upper
    // bound for T.
    return value == null ? null : (value as dynamic).index as int;
  }
}
