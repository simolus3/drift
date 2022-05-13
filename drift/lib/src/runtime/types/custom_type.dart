part of 'sql_types.dart';

/// Maps a custom dart object of type [D] into a primitive type [S] understood
/// by the sqlite backend.
///
/// Dart currently supports [DateTime], [double], [int], [Uint8List], [bool]
/// and [String] for [S].
///
/// Using a type converter does impact the way drift serializes data classes to
/// JSON by default. To control that, use a [JsonTypeConverter] or a custom
/// [ValueSerializer].
///
/// Also see [BuildGeneralColumn.map] for details.
abstract class TypeConverter<D, S> {
  /// Empty constant constructor so that subclasses can have a constant
  /// constructor.
  const TypeConverter();

  /// Map a value from an object in Dart into something that will be understood
  /// by the database.
  S? mapToSql(D? value);

  /// Maps a column from the database back to Dart.
  D? mapToDart(S? fromDb);
}

/// A mixin for [TypeConverter]s that should also apply to drift's builtin
/// JSON serialization of data classes.
///
/// By default, a [TypeConverter] only applies to the serialization from Dart
/// to SQL (and vice-versa).
/// When a [BuildGeneralColumn.map] column (or a `MAPPED BY` constraint in
/// `.drift` files) refers to a type converter that inherits from
/// [JsonTypeConverter], it will also be used to conversion from and to json.
mixin JsonTypeConverter<D, S> on TypeConverter<D, S> {
  /// Map a value from the Data class to json.
  ///
  /// Defaults to doing the same conversion as for Dart -> SQL, [mapToSql].
  S? toJson(D? value) => mapToSql(value);

  /// Map a value from json to something understood by the data class.
  ///
  /// Defaults to doing the same conversion as for SQL -> Dart, [mapToSql].
  D? fromJson(S? json) => mapToDart(json);
}

/// Implementation for an enum to int converter that uses the index of the enum
/// as the value stored in the database.
class EnumIndexConverter<T> extends NullAwareTypeConverter<T, int> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const EnumIndexConverter(this.values);

  @override
  T requireMapToDart(int fromDb) {
    return values[fromDb];
  }

  @override
  int requireMapToSql(T value) {
    // In Dart 2.14: Cast to Enum instead of dynamic. Also add Enum as an upper
    // bound for T.
    return (value as dynamic).index as int;
  }
}

/// A type converter automatically mapping `null` values to `null` in both
/// directions.
///
/// Instead of overriding  [mapToDart] and [mapToSql], subclasses of this
/// converter should implement [requireMapToDart] and [requireMapToSql], which
/// are used to map non-null values to and from sql values, respectively.
///
/// Apart from the implementation changes, subclasses of this converter can be
/// used just like all other type converters.
abstract class NullAwareTypeConverter<D, S extends Object>
    extends TypeConverter<D, S> {
  /// Constant default constructor.
  const NullAwareTypeConverter();

  @override
  D? mapToDart(S? fromDb) {
    return fromDb == null ? null : requireMapToDart(fromDb);
  }

  /// Maps a non-null column from the database back to Dart.
  D requireMapToDart(S fromDb);

  @override
  S? mapToSql(D? value) {
    return value == null ? null : requireMapToSql(value);
  }

  /// Map a non-null value from an object in Dart into something that will be
  /// understood by the database.
  S requireMapToSql(D value);
}
