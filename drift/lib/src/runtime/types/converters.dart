import 'dart:typed_data';
import 'dart:convert' as convert;

import '../../dsl/dsl.dart';
import '../data_class.dart';

/// Maps a custom dart object of type [D] into a primitive type [S] understood
/// by the sqlite backend.
///
/// Dart currently supports [DateTime], [double], [int], [Uint8List], [bool]
/// and [String] for [S].
///
/// Using a type converter does not impact the way drift serializes data classes to
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

  /// Creates a type converter for storing complex Dart objects in a text column
  /// by serializing them as JSON.
  ///
  /// This requires supplying [fromJson], a function responsible for mapping the
  /// parsed JSON structure to the Dart type [D]. Optionally, you can also
  /// be explicit about the other direction via [toJson]. By default, Dart's
  /// JSON encoder simply calls `toJson()` on the object.
  ///
  /// Finally, the [json] codec itself can be customized as well if needed.
  static JsonTypeConverter<D, String> json<D>({
    required D Function(dynamic json) fromJson,
    dynamic Function(D column)? toJson,
    convert.JsonCodec json = convert.json,
  }) {
    return _JsonBasedConverter<D>(
      mapFromJson: fromJson,
      mapToJson: toJson ?? (value) => value,
      json: json,
    );
  }
}

/// A mixin for [TypeConverter]s that should also apply to drift's builtin
/// JSON serialization of data classes.
///
/// Unlike the old [JsonTypeConverter] mixin, this more general mixin allows
/// using a different type when serializing to JSON ([J]) than the type used in
/// SQL ([S]).
/// For the cases where the JSON serialization and the mapping to SQL use the
/// same types, it may be more convenient to mix-in [JsonTypeConverter] instead.
mixin JsonTypeConverter2<D, S, J> on TypeConverter<D, S> {
  /// Map a value from the Data class to json.
  ///
  /// Defaults to doing the same conversion as for Dart -> SQL, [toSql].
  J toJson(D value);

  /// Map a value from json to something understood by the data class.
  ///
  /// Defaults to doing the same conversion as for SQL -> Dart, [toSql].
  D fromJson(J json);

  /// Wraps an [inner] type converter that only considers non-nullable values
  /// as a type converter that handles null values too.
  ///
  /// The returned type converter will use the [inner] type converter for non-
  /// null values. Further, `null` is mapped to `null` in both directions (from
  /// Dart to SQL and vice-versa).
  static JsonTypeConverter2<D?, S?, J?>
      asNullable<D, S extends Object, J extends Object>(
          JsonTypeConverter2<D, S, J> inner) {
    return _NullWrappingTypeConverterWithJson(inner);
  }
}

/// A mixin for [TypeConverter]s that should also apply to drift's builtin
/// JSON serialization of data classes.
///
/// By default, a [TypeConverter] only applies to the serialization from Dart
/// to SQL (and vice-versa).
/// When a [BuildGeneralColumn.map] column (or a `MAPPED BY` constraint in
/// `.drift` files) refers to a type converter that inherits from
/// [JsonTypeConverter], it will also be used for the conversion from and to
/// JSON.
///
/// If the serialized JSON has a different type than the type in SQL ([S]), use
/// a [JsonTypeConverter2]. For instance, this could be useful if your type
/// converter between Dart and SQL maps to a string in SQL, but to a `Map` in
/// JSON.
mixin JsonTypeConverter<D, S> implements JsonTypeConverter2<D, S, S> {
  @override
  S toJson(D value) => toSql(value);

  @override
  D fromJson(S json) => fromSql(json);
}

/// Implementation for an enum to int converter that uses the index of the enum
/// as the value stored in the database.
class EnumIndexConverter<T extends Enum> extends TypeConverter<T, int>
    with JsonTypeConverter<T, int> {
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

/// Implementation for an enum to string converter that uses the name of the
/// enum as the value stored in the database.
class EnumNameConverter<T extends Enum> extends TypeConverter<T, String>
    with JsonTypeConverter<T, String> {
  /// All values of the enum.
  final List<T> values;

  /// Constant default constructor.
  const EnumNameConverter(this.values);

  @override
  T fromSql(String fromDb) {
    return values.byName(fromDb);
  }

  @override
  String toSql(T value) {
    return value.name;
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

  /// Invokes a non-nullable [inner] type converter for a single conversion from
  /// SQL to Dart.
  ///
  /// Returns `null` if [sqlValue] is `null`, [TypeConverter.fromSql] otherwise.
  /// This method is mostly intended to be used for code generated by drift-dev.
  static D? wrapFromSql<D, S>(TypeConverter<D, S> inner, S? sqlValue) {
    return sqlValue == null ? null : inner.fromSql(sqlValue);
  }

  /// Invokes a non-nullable [inner] type converter for a single conversion from
  /// Dart to SQL.
  ///
  /// Returns `null` if [dartValue] is `null`, [TypeConverter.toSql] otherwise.
  /// This method is mostly intended to be used for code generated by drift-dev.
  static S? wrapToSql<D, S>(TypeConverter<D, S> inner, D? dartValue) {
    return dartValue == null ? null : inner.toSql(dartValue);
  }
}

class _JsonBasedConverter<D> extends TypeConverter<D, String>
    with JsonTypeConverter<D, String> {
  final D Function(dynamic json) mapFromJson;
  final dynamic Function(D column) mapToJson;
  final convert.JsonCodec json;

  _JsonBasedConverter(
      {required this.mapFromJson, required this.mapToJson, required this.json});

  @override
  D fromSql(String fromDb) {
    return mapFromJson(json.decode(fromDb));
  }

  @override
  String toSql(D value) {
    return json.encode(mapToJson(value));
  }
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

class _NullWrappingTypeConverterWithJson<D, S extends Object, J extends Object>
    extends NullAwareTypeConverter<D, S>
    implements JsonTypeConverter2<D?, S?, J?> {
  final JsonTypeConverter2<D, S, J> _inner;

  const _NullWrappingTypeConverterWithJson(this._inner);

  @override
  D requireFromSql(S fromDb) => _inner.fromSql(fromDb);

  @override
  S requireToSql(D value) => _inner.toSql(value);

  D requireFromJson(J json) => _inner.fromJson(json);

  @override
  D? fromJson(J? json) {
    return json == null ? null : requireFromJson(json);
  }

  J? requireToJson(D? value) => _inner.toJson(value as D);

  @override
  J? toJson(D? value) {
    return value == null ? null : requireToJson(value);
  }
}
