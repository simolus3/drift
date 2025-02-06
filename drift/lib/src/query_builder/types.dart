import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'dialect.dart';

typedef TypedValue<T extends Object> = (SqlType<T>, T);

typedef TypedNullableValue<T extends Object> = (SqlType<T>, T?);

final class DatabaseJson {
  final Object? dartValue;

  DatabaseJson(this.dartValue);

  Object? toJson() => dartValue;
}

/// The base class for column types in databases.
abstract base class SqlType<T extends Object> {
  /// Default const constructor so that subclasses can be const.
  const SqlType();

  String typeName(DriftDialect dialect);

  Object sqlParameter(DriftDialect dialect, T value);
  String sqlLiteral(DriftDialect dialect, T value);

  T dartValue(DriftDialect dialect, Object databaseValue);
}

/// Provides access types that every drift dialect implementation must support.
abstract interface class TypeProvider {
  /// Returns a type implementation suitable for storing UTF-8 texts without
  /// length restrictions.
  SqlType<String> get textType;

  /// Returns a type implementation suitable for storing 64-bit signed integers.
  SqlType<int> get intType;

  /// Returns a type implementation suitable for storing [double] values.
  SqlType<double> get doubleType;

  /// Returns a type implementation suitable for storing byte arrays without a
  /// length restriction.
  SqlType<Uint8List> get byteArrayType;

  /// Returns a type implementation suitable for storing [DateTime] values.
  ///
  /// The underlying implementation may store values with less precision than
  /// supported by [DateTime] instances. It may also not support timezones
  /// (meaning that local [DateTime] values may be returned as UTC [DateTime]s
  /// or vice-versa), but must not return [DateTime] values occuring at a
  /// different instant due to timezone information loss.
  SqlType<DateTime> get dateTimeType;

  /// Returns a type implementation suitable for storing JSON values.
  ///
  /// Drift makes no assumption about the underlying JSON representation in the
  /// database, implementations are free to use a binary or a textual
  /// representation.
  SqlType<DatabaseJson> get jsonType;

  /// Returns a type implementation suitable for storing boolean values.
  SqlType<bool> get boolType;

  /// Return a [SqlType] instance for a Dart type [T], or throw if that
  /// operation is not supported.
  ///
  /// An implementation can delegate to [BuiltinDriftType.forType].
  SqlType<T> resolveType<T extends Object>();
}

interface class _BuiltinDriftTypeWithoutBound<T> {}

enum BuiltinDriftType<T extends Object>
    implements _BuiltinDriftTypeWithoutBound<T> {
  text<core.String>._(),
  int<core.int>._(),
  double<core.double>._(),
  byteArray<Uint8List>._(),
  bool<core.bool>._(),
  dateTime<DateTime>._(),
  json<DatabaseJson>._();

  const BuiltinDriftType._();

  /// Returns the implementation of this type in a [TypeProvider] (most commonly
  /// a [DriftDialect] instance).
  SqlType<T> resolveIn(TypeProvider implementation) {
    return switch (this) {
      BuiltinDriftType.text => implementation.textType,
      BuiltinDriftType.int => implementation.intType,
      BuiltinDriftType.double => implementation.doubleType,
      BuiltinDriftType.byteArray => implementation.byteArrayType,
      BuiltinDriftType.json => implementation.jsonType,
      BuiltinDriftType.bool => implementation.boolType,
      BuiltinDriftType.dateTime => implementation.dateTimeType,
    } as SqlType<T>;
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
      Map<Type, BuiltinDriftType> map, BuiltinDriftType<Object> type) {
    map[T] = type;
  }

  /// Attempts to find a suitable SQL type for the [Dart] type passed to this
  /// method.
  ///
  /// The [Dart] type must be the type of the instance _after_ applying type
  /// converters.
  static BuiltinDriftType<Dart> forType<Dart extends Object>() {
    final type = _dartToDrift[Dart];

    if (type == null) {
      throw ArgumentError('Could not find a matching SQL type for $Dart');
    }

    return type as BuiltinDriftType<Dart>;
  }

  /// A variant of [forType] that also works for nullable [Dart] types.
  ///
  /// Using [forType] should pretty much always be preferred over this method,
  /// this one just exists for backwards compatibility.
  static BuiltinDriftType forNullableType<Dart>() {
    // Lookup the type in the map first for faster lookups. Go back to a full
    // typecheck where that doesn't work (which can be the case for complex
    // type like `forNullableType<FutureOr<int?>>`).
    final type = _dartToDrift[Dart] ??
        values.whereType<_BuiltinDriftTypeWithoutBound<Dart>>().singleOrNull;

    if (type == null) {
      throw ArgumentError('Could not find a matching SQL type for $Dart');
    }

    return type as BuiltinDriftType;
  }
}
