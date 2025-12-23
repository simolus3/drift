import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:collection/collection.dart';

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
abstract interface class SqlType<T extends Object> {
  /// Creates a [SqlType] implementation based on a [fallback] type
  /// implementation used by default and [overrides] used as fallbacks.
  const factory SqlType.dialectSpecific({
    required SqlType<T> fallback,
    required Map<KnownSqlDialect, SqlType<T>> overrides,
  }) = _DialectAwareType;

  /// Resolves an implementation of the type in the given dialect.
  PhysicalSqlType<T> resolveIn(DriftDialect dialect);
}

/// Adds type implementation methods to [SqlType] by looking up the type in a
/// [DriftDialect] implementation.

extension TypeExtension<T extends Object> on SqlType<T> {
  /// The name of the type in SQL, e.g. in a column definition or a `CAST`.
  String typeName(DriftDialect dialect) => resolveIn(dialect).typeName;

  /// Maps a Dart [value] to bind to a parameter in a generated statement to a
  /// value understood by database drivers.
  Object sqlParameter(DriftDialect dialect, T value) {
    return resolveIn(dialect).dartValue(value);
  }
}

/// A dialect-specific implementation of a [SqlType].
abstract base class PhysicalSqlType<T extends Object> implements SqlType<T> {
  /// The name of the type in SQL, e.g. in a column definition or a `CAST`.
  String get typeName;

  /// Maps a Dart [value] to bind to a parameter in a generated statement to a
  /// value understood by database drivers.
  Object sqlParameter(T value);

  /// Maps [value] to its (escaped) SQL literal.
  String sqlLiteral(T value);

  /// Maps a raw value returned in a raw result set into the [T] for [SqlType].
  T dartValue(Object databaseValue);

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

  /// Return a [SqlType] instance for a Dart type [T], or throw if that
  /// operation is not supported.
  ///
  /// An implementation can delegate to [BuiltinDriftType.forType].
  PhysicalSqlType<T> resolveType<T extends Object>();
}

interface class _BuiltinDriftTypeWithoutBound<T> {}

/// A builtin type drift expects every database to implement.
///
/// These are not necessarily different types in all databases. For instance,
/// SQLite does not have a dedicated [json] type. So depending on dialect
/// options, drift would use a `TEXT` or `BLOB` (JSONB) type for that.
enum BuiltinDriftType<T extends Object>
    implements _BuiltinDriftTypeWithoutBound<T>, SqlType<T> {
  /// A type suitable for storing text of arbitrary length.
  text<core.String>._(),

  /// A type suitable for storing 64-bit integers.
  int<core.int>._(),

  /// Guaranteed to be the same SQL type as [int], but stores [BigInt] values
  /// to ensure we don't loose precision when compiling Dart to JavaScript
  /// (where ints are doubles).
  int64<core.BigInt>._(),

  /// A type suitable for storing double values.
  double<core.double>._(),

  /// A type suitable for storing byte arrays as blobs.
  byteArray<Uint8List>._(),

  /// A type suitable for storing boolean values.
  bool<core.bool>._(),

  /// A type suitable for storing datetime values.
  dateTime<DateTime>._(),

  /// A type suitable for storing JSON values.
  json<DatabaseJson>._();

  const BuiltinDriftType._();

  /// Returns the implementation of this type in a [TypeProvider] (most commonly
  /// a [DriftDialect] instance).
  @override
  PhysicalSqlType<T> resolveIn(TypeProvider implementation) {
    return switch (this) {
          BuiltinDriftType.text => implementation.textType,
          BuiltinDriftType.int => implementation.intType,
          BuiltinDriftType.int64 => implementation.int64Type,
          BuiltinDriftType.double => implementation.doubleType,
          BuiltinDriftType.byteArray => implementation.byteArrayType,
          BuiltinDriftType.json => implementation.jsonType,
          BuiltinDriftType.bool => implementation.boolType,
          BuiltinDriftType.dateTime => implementation.dateTimeType,
        }
        as PhysicalSqlType<T>;
  }

  void _addToMap(Map<Type, BuiltinDriftType> map) {
    _addToTypeMap<T>(map, this);
    // Unfortunately, `T?` by itself is not an expression so we have to jump
    // through hoops to add the nullable variant to the type map.
    _addToTypeMap<T?>(map, this);
  }

  static Map<Type, BuiltinDriftType> _dartToDrift = () {
    final map = <Type, BuiltinDriftType>{};

    for (final value in values) {
      value._addToMap(map);
    }

    return map;
  }();

  static void _addToTypeMap<T>(
    Map<Type, BuiltinDriftType> map,
    BuiltinDriftType<Object> type,
  ) {
    map[T] = type;
  }

  /// Attempts to find a suitable SQL type for the [Dart] type passed to this
  /// method.
  ///
  /// The [Dart] type must be the type of the instance _after_ applying type
  /// converters.
  static BuiltinDriftType<Dart>? forType<Dart extends Object>() {
    final type = _dartToDrift[Dart];

    if (type == null) {
      return null;
    }

    return type as BuiltinDriftType<Dart>;
  }

  /// A variant of [forType] that also works for nullable [Dart] types.
  ///
  /// Using [forType] should pretty much always be preferred over this method,
  /// this one just exists for backwards compatibility.
  static BuiltinDriftType? forNullableType<Dart>() {
    // Lookup the type in the map first for faster lookups. Go back to a full
    // typecheck where that doesn't work (which can be the case for complex
    // type like `forNullableType<FutureOr<int?>>`).
    final type =
        _dartToDrift[Dart] ??
        values.whereType<_BuiltinDriftTypeWithoutBound<Dart>>().singleOrNull;

    if (type == null) {
      return null;
    }

    return type as BuiltinDriftType;
  }

  /// Attempts to resolve a [BuiltinDriftType] for the type of [value].
  ///
  /// The static variants ([forType] and [forNullableType] should almost always
  /// be preferred to this because they can assign types to null values too).
  static BuiltinDriftType? forValue(Object? value) {
    return _dartToDrift[value.runtimeType];
  }
}
