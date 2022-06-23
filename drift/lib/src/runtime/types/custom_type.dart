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
  S toSql(D value);

  /// Maps a column from the database back to Dart.
  D fromSql(S fromDb);
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
  /// Defaults to doing the same conversion as for Dart -> SQL, [toSql].
  S toJson(D value) => toSql(value);

  /// Map a value from json to something understood by the data class.
  ///
  /// Defaults to doing the same conversion as for SQL -> Dart, [toSql].
  D fromJson(S json) => fromSql(json);

  /// Wraps an [inner] type converter that only considers non-nullable values
  /// as a type converter that handles null values too.
  ///
  /// The returned type converter will use the [inner] type converter for non-
  /// null values. Further, `null` is mapped to `null` in both directions (from
  /// Dart to SQL and vice-versa).
  static JsonTypeConverter<D?, S?> asNullable<D, S extends Object>(
      TypeConverter<D, S> inner) {
    return _NullWrappingTypeConverterWithJson(inner);
  }
}

/// Implementation for an enum to int converter that uses the index of the enum
/// as the value stored in the database.
class EnumIndexConverter<T extends Enum> extends TypeConverter<T, int> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const EnumIndexConverter(this.values);

  @override
  T fromSql(int fromDb) {
    return values[fromDb];
  }

  @override
  int toSql(T value) {
    return value.index;
  }
}

/// A type converter automatically mapping `null` values to `null` in both
/// directions.
///
/// Instead of overriding  [fromSql] and [toSql], subclasses of this
/// converter should implement [requireFromSql] and [requireToSql], which
/// are used to map non-null values to and from sql values, respectively.
///
/// Apart from the implementation changes, subclasses of this converter can be
/// used just like all other type converters.
abstract class NullAwareTypeConverter<D, S extends Object>
    extends TypeConverter<D?, S?> {
  /// Constant default constructor, allowing subclasses to be constant.
  const NullAwareTypeConverter();

  /// Wraps an [inner] type converter that only considers non-nullable values
  /// as a type converter that handles null values too.
  ///
  /// The returned type converter will use the [inner] type converter for non-
  /// null values. Further, `null` is mapped to `null` in both directions (from
  /// Dart to SQL and vice-versa).
  const factory NullAwareTypeConverter.wrap(TypeConverter<D, S> inner) =
      _NullWrappingTypeConverter<D, S>;

  @override
  D? fromSql(S? fromDb) {
    return fromDb == null ? null : requireFromSql(fromDb);
  }

  /// Maps a non-null column from the database back to Dart.
  D requireFromSql(S fromDb);

  @override
  S? toSql(D? value) {
    return value == null ? null : requireToSql(value);
  }

  /// Map a non-null value from an object in Dart into something that will be
  /// understood by the database.
  S requireToSql(D value);
}

class _NullWrappingTypeConverter<D, S extends Object>
    extends NullAwareTypeConverter<D, S> {
  final TypeConverter<D, S> _inner;

  const _NullWrappingTypeConverter(this._inner);

  @override
  D requireFromSql(S fromDb) => _inner.fromSql(fromDb);

  @override
  S requireToSql(D value) => _inner.toSql(value);
}

class _NullWrappingTypeConverterWithJson<D, S extends Object>
    extends NullAwareTypeConverter<D, S> with JsonTypeConverter<D?, S?> {
  final TypeConverter<D, S> _inner;

  const _NullWrappingTypeConverterWithJson(this._inner);

  @override
  D requireFromSql(S fromDb) => _inner.fromSql(fromDb);

  @override
  S requireToSql(D value) => _inner.toSql(value);
}
