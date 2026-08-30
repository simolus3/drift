import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'dialect.dart';

/// A JSON value in a drift database.
///
/// This is a dedicated class to ensure that e.g. JSON strings are still
/// represented as [DatabaseJson]s consistently (whereas raw [String]s might be
/// interpreted as raw text).
final class DatabaseJson {
  /// The decoded JSON value.
  final Object? dartValue;

  /// @nodoc
  const DatabaseJson(this.dartValue);

  /// Returns the [dartValue].
  Object? toJson() => dartValue;

  @override
  int get hashCode => dartValue.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DatabaseJson && other.dartValue == dartValue;
  }

  @override
  String toString() {
    return dartValue.toString();
  }
}

/// The base class for column types in databases.
///
/// This interface describes a logical, dialect-independent SQL type. The actual
/// type used in the underlying database is resolved to a [PhysicalSqlType] vi
/// [resolveIn]. That mapping is dialect-specific, and can even depend on
/// dialect options. For example, [BuiltinSqlType.dateTime] resolves to a text
/// or integer type for SQLite databases depending on a options.
abstract interface class SqlType<T extends Object> {
  /// Creates a [SqlType] implementation based on a [fallback] type
  /// implementation used by default and [overrides] used as fallbacks.
  const factory SqlType.dialectSpecific({
    required SqlType<T> fallback,
    required Map<KnownSqlDialect, SqlType<T>> overrides,
  }) = _DialectAwareType;

  /// Resolves an implementation of the type in the given dialect.
  PhysicalSqlType<T> resolveIn(DriftDialect dialect);

  /// A type suitable for storing text of arbitrary length.
  static const SqlType<core.String> text = BuiltinSqlType.text;

  /// A type suitable for storing 64-bit integers.
  static const SqlType<core.int> int = BuiltinSqlType.int;

  /// Guaranteed to be the same SQL type as [int], but stores [BigInt] values
  /// to ensure we don't loose precision when compiling Dart to JavaScript
  /// (where ints are doubles).
  static const SqlType<core.BigInt> int64 = BuiltinSqlType.int64;

  /// A type suitable for storing double values.
  static const SqlType<core.double> double = BuiltinSqlType.double;

  /// A type suitable for storing byte arrays as blobs.
  static const SqlType<Uint8List> byteArray = BuiltinSqlType.byteArray;

  /// A type suitable for storing boolean values.
  static const SqlType<core.bool> bool = BuiltinSqlType.bool;

  /// A type suitable for storing datetime values.
  static const SqlType<core.DateTime> dateTime = BuiltinSqlType.dateTime;

  /// A type suitable for storing JSON values.
  static const SqlType<DatabaseJson> json = BuiltinSqlType.json;
}

/// Adds type implementation methods to [SqlType] by looking up the type in a
/// [DriftDialect] implementation.

extension TypeExtension<T extends Object> on SqlType<T> {
  /// The name of the type in SQL, e.g. in a column definition or a `CAST`.
  String typeName(DriftDialect dialect) => resolveIn(dialect).typeName;

  /// Maps a Dart [value] to bind to a parameter in a generated statement to a
  /// value understood by database drivers.
  Object? sqlParameter(DriftDialect dialect, T? value) {
    return resolveIn(dialect).sqlParameter(value);
  }
}

/// A dialect-specific implementation of a [SqlType].
abstract base class PhysicalSqlType<T extends Object> implements SqlType<T> {
  /// @nodoc
  const PhysicalSqlType();

  /// The name of the type in SQL, e.g. in a column definition or a `CAST`.
  String get typeName;

  /// Maps a Dart [value] to bind to a parameter in a generated statement to a
  /// value understood by database drivers.
  Object? sqlParameter(T? value);

  /// Maps [value] to its (escaped) SQL literal.
  String sqlLiteral(T value);

  /// Maps a raw value returned in a raw result set into the [T] for [SqlType].
  T dartValue(Object databaseValue);

  /// Like [dartValue], except that it supports null values which are forwarded
  /// unchanged.
  T? nullableDartValue(Object? databaseValue) {
    return databaseValue == null ? null : dartValue(databaseValue);
  }

  @override
  PhysicalSqlType<T> resolveIn(DriftDialect dialect) {
    return this;
  }
}

final class _DialectAwareType<T extends Object> implements SqlType<T> {
  final SqlType<T> fallback;
  final Map<KnownSqlDialect, SqlType<T>> overrides;

  const _DialectAwareType({required this.fallback, required this.overrides});

  SqlType<T> _implementationFor(DriftDialect dialect) {
    return overrides[dialect.known] ?? fallback;
  }

  @override
  PhysicalSqlType<T> resolveIn(DriftDialect dialect) {
    return _implementationFor(dialect).resolveIn(dialect);
  }
}

/// Provides access types that every drift dialect implementation must support.
abstract interface class TypeProvider {
  /// Returns a type implementation suitable for storing UTF-8 texts without
  /// length restrictions.
  PhysicalSqlType<String> get textType;

  /// Returns a type implementation suitable for storing 64-bit signed integers.
  PhysicalSqlType<int> get intType;

  /// Returns a type implementation suitable for storing 64-bit signed integers
  /// that are represented as a [BigInt] in Dart.
  PhysicalSqlType<BigInt> get int64Type;

  /// Returns a type implementation suitable for storing [double] values.
  PhysicalSqlType<double> get doubleType;

  /// Returns a type implementation suitable for storing byte arrays without a
  /// length restriction.
  PhysicalSqlType<Uint8List> get byteArrayType;

  /// Returns a type implementation suitable for storing [DateTime] values.
  ///
  /// The underlying implementation may store values with less precision than
  /// supported by [DateTime] instances. It may also not support timezones
  /// (meaning that local [DateTime] values may be returned as UTC [DateTime]s
  /// or vice-versa), but must not return [DateTime] values occuring at a
  /// different instant due to timezone information loss.
  PhysicalSqlType<DateTime> get dateTimeType;

  /// Returns a type implementation suitable for storing JSON values.
  ///
  /// Drift makes no assumption about the underlying JSON representation in the
  /// database, implementations are free to use a binary or a textual
  /// representation.
  PhysicalSqlType<DatabaseJson> get jsonType;

  /// Returns a type implementation suitable for storing boolean values.
  PhysicalSqlType<bool> get boolType;
}

interface class _BuiltinSqlTypeWithoutBound<T> {}

/// A builtin type drift expects every database to implement.
///
/// These are not necessarily different types in all databases. For instance,
/// SQLite does not have a dedicated [json] type. So depending on dialect
/// options, drift would use a `TEXT` or `BLOB` (JSONB) type for that.
@internal
enum BuiltinSqlType<T extends Object>
    implements _BuiltinSqlTypeWithoutBound<T>, SqlType<T> {
  text<core.String>._(),
  int<core.int>._(),
  int64<core.BigInt>._(),
  double<core.double>._(),
  byteArray<Uint8List>._(),
  bool<core.bool>._(),
  dateTime<DateTime>._(),
  json<DatabaseJson>._();

  const BuiltinSqlType._();

  /// Returns the implementation of this type in a [TypeProvider] (most commonly
  /// a [DriftDialect] instance).
  @override
  PhysicalSqlType<T> resolveIn(TypeProvider implementation) {
    return switch (this) {
          BuiltinSqlType.text => implementation.textType,
          BuiltinSqlType.int => implementation.intType,
          BuiltinSqlType.int64 => implementation.int64Type,
          BuiltinSqlType.double => implementation.doubleType,
          BuiltinSqlType.byteArray => implementation.byteArrayType,
          BuiltinSqlType.json => implementation.jsonType,
          BuiltinSqlType.bool => implementation.boolType,
          BuiltinSqlType.dateTime => implementation.dateTimeType,
        }
        as PhysicalSqlType<T>;
  }

  void _addToMap(Map<Type, BuiltinSqlType> map) {
    _addToTypeMap<T>(map, this);
    // Unfortunately, `T?` by itself is not an expression so we have to jump
    // through hoops to add the nullable variant to the type map.
    _addToTypeMap<T?>(map, this);
  }

  static Map<Type, BuiltinSqlType> _dartToDrift = () {
    final map = <Type, BuiltinSqlType>{};

    for (final value in values) {
      value._addToMap(map);
    }

    return map;
  }();

  static void _addToTypeMap<T>(
    Map<Type, BuiltinSqlType> map,
    BuiltinSqlType<Object> type,
  ) {
    map[T] = type;
  }

  /// Attempts to find a suitable SQL type for the [Dart] type passed to this
  /// method.
  ///
  /// The [Dart] type must be the type of the instance _after_ applying type
  /// converters.
  static BuiltinSqlType<Dart>? forType<Dart extends Object>() {
    final type = _dartToDrift[Dart];

    if (type == null) {
      return null;
    }

    return type as BuiltinSqlType<Dart>;
  }

  /// A variant of [forType] that also works for nullable [Dart] types.
  ///
  /// Using [forType] should pretty much always be preferred over this method,
  /// this one just exists for backwards compatibility.
  static BuiltinSqlType? forNullableType<Dart>() {
    // Lookup the type in the map first for faster lookups. Go back to a full
    // typecheck where that doesn't work (which can be the case for complex
    // type like `forNullableType<FutureOr<int?>>`).
    final type =
        _dartToDrift[Dart] ??
        values.whereType<_BuiltinSqlTypeWithoutBound<Dart>>().singleOrNull;

    if (type == null) {
      return null;
    }

    return type as BuiltinSqlType;
  }

  /// Attempts to resolve a [BuiltinSqlType] for the type of [value].
  ///
  /// The static variants ([forType] and [forNullableType] should almost always
  /// be preferred to this because they can assign types to null values too).
  static BuiltinSqlType? forValue(Object? value) {
    return _dartToDrift[value.runtimeType];
  }
}
