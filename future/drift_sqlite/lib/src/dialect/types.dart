import 'dart:convert';
import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:drift3_preview/internal/common_dialect.dart';

import 'package:sqlite3/common.dart' show jsonb;

/// The type implementation for ints.
const intType = _IntType();

/// Like [intType], but mapping to [BigInt]s.
const bigIntType = _BigIntType();

/// The SQLite type implementation for strings.
const textType = CommonTextType();

/// The SQLite type implementation for blobs.
const blobType = CommonByteArrayType('BLOB');

abstract base class _SqliteType<T extends Object> extends PhysicalSqlType<T> {
  @override
  final String typeName;

  const _SqliteType(this.typeName);

  @override
  T dartValue(Object databaseValue) {
    return databaseValue as T;
  }

  @override
  Object? sqlParameter(T? value) {
    return value;
  }
}

final class _SqlTypeWithoutMapping<T extends Object> extends _SqliteType<T> {
  const _SqlTypeWithoutMapping(super.name);

  @override
  String sqlLiteral(T value) {
    return value.toString();
  }
}

/// The boolean type, implemented as an `INTEGER` that is either `0` or `1`.
final class BoolType extends _SqlTypeWithoutMapping<bool> {
  /// @nodoc
  const BoolType() : super('INTEGER');

  @override
  bool dartValue(Object databaseValue) {
    return databaseValue != 0 && databaseValue != false;
  }

  @override
  Object? sqlParameter(bool? value) {
    return switch (value) {
      null => null,
      true => 1,
      false => 0,
    };
  }

  @override
  String sqlLiteral(bool value) {
    return value ? '1' : '0';
  }
}

final class _IntType extends _SqlTypeWithoutMapping<int> {
  const _IntType() : super('INTEGER');

  @override
  int dartValue(Object databaseValue) {
    return switch (databaseValue) {
      int() => databaseValue,
      BigInt() => databaseValue.toInt(),
      double() => databaseValue.toInt(),
      _ => int.parse(databaseValue.toString()),
    };
  }
}

final class _BigIntType extends _SqlTypeWithoutMapping<BigInt> {
  const _BigIntType() : super('INTEGER');

  @override
  BigInt dartValue(Object databaseValue) {
    return switch (databaseValue) {
      int() => BigInt.from(databaseValue),
      BigInt() => databaseValue,
      double() => BigInt.from(databaseValue.toInt()),
      _ => BigInt.parse(databaseValue.toString()),
    };
  }
}

/// A [DateTime] type implementation.
final class DateTimeType extends _SqliteType<DateTime> {
  final bool _asText;

  /// A [DateTime] type implementation storing [DateTime.toIso8601String]
  /// values.
  const DateTimeType.text() : _asText = true, super('TEXT');

  /// A [DateTime] type implementation storing unix timestamps.
  const DateTimeType.timestamps() : _asText = false, super('INTEGER');

  @override
  DateTime dartValue(Object databaseValue) {
    if (_asText) {
      final rawValue = databaseValue.toString();
      DateTime result;

      // We store date times like this:
      //
      //  - if it's in UTC, we call [DateTime.toIso8601String], so there's a
      //    trailing `Z`. We can just use [DateTime.parse] and get an utc
      //    datetime back.
      //  - for local date times, we append the time zone offset, e.g.
      //    `+02:00`. [DateTime.parse] respects this UTC offset and returns
      //    the correct date, but it returns it in UTC. Since we only use
      //    this format for local times, we need to transform it back to
      //    local.
      //
      // Additionally, complex date time expressions are wrapped in a
      // `datetime` sqlite call, which doesn't append a `Z` or a time zone
      // offset. As sqlite3 always uses UTC for these computations
      // internally, we'll return a UTC datetime as well.
      if (_timeZoneInDateTime.hasMatch(rawValue)) {
        // Case 2: Explicit time zone offset given, we do this for local
        // dates.
        result = DateTime.parse(rawValue).toLocal();
      } else if (rawValue.endsWith('Z')) {
        // Case 1: Date time in UTC, [DateTime.parse] will do the right
        // thing.
        result = DateTime.parse(rawValue);
      } else {
        // Result from complex date time transformation. Interpret as UTC,
        // which is what sqlite3 does by default.
        result = DateTime.parse('${rawValue}Z');
      }

      return result;
    } else {
      return DateTime.fromMillisecondsSinceEpoch(
        1000 * intType.dartValue(databaseValue),
      );
    }
  }

  @override
  Object? sqlParameter(DateTime? value) {
    if (value == null) return null;

    if (_asText) {
      // sqlite3 assumes UTC by default, so we store the explicit UTC offset
      // along with the value. For UTC datetimes, there's nothing to change
      if (value.isUtc) {
        return value.toIso8601String();
      } else {
        final offset = value.timeZoneOffset;
        // Quick sanity check: We can only store the UTC offset as `hh:mm`,
        // so if the offset has seconds for some reason we should refuse to
        // store that.
        if (offset.inSeconds - 60 * offset.inMinutes != 0) {
          throw ArgumentError.value(
            dartValue,
            'dartValue',
            'Cannot be mapped to SQL: Invalid UTC offset $offset',
          );
        }

        final hours = offset.inHours.abs();
        final minutes = offset.inMinutes.abs() - 60 * hours;

        // For local date times, add the offset as ` +hh:mm` in the end. This
        // format is understood by `DateTime.parse` and date time functions in
        // sqlite.
        final prefix = offset.isNegative ? ' -' : ' +';
        final formattedOffset =
            '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}';

        return '${value.toIso8601String()}$prefix$formattedOffset';
      }
    } else {
      return value.millisecondsSinceEpoch ~/ 1000;
    }
  }

  @override
  String sqlLiteral(DateTime value) {
    final param = sqlParameter(value);
    return switch (param) {
      String s => "'$s'",
      final other => other.toString(),
    };
  }

  // Stolen from DateTime._parseFormat
  static final RegExp _timeZoneInDateTime = RegExp(
    r' ?([-+])(\d\d)(?::?(\d\d))?$',
  );
}

/// A `JSON` type implementation using text or binary values for SQLite.
final class JsonType extends _SqliteType<DatabaseJson> {
  final bool _useBinary;

  /// A text-based JSON type.
  const JsonType.asText() : _useBinary = false, super('TEXT');

  /// A binary JSONB type.
  const JsonType.asBinary() : _useBinary = true, super('BLOB');

  @override
  String sqlLiteral(DatabaseJson value) {
    if (_useBinary) {
      return blobType.sqlLiteral(jsonb.encode(value.dartValue));
    } else {
      return textType.sqlLiteral(json.encode(value.dartValue));
    }
  }

  @override
  Object? sqlParameter(DatabaseJson? value) {
    if (value == null) return null;

    if (_useBinary) {
      return jsonb.encode(value.dartValue);
    } else {
      return json.encode(value.dartValue);
    }
  }

  @override
  DatabaseJson dartValue(Object databaseValue) {
    if (_useBinary) {
      return DatabaseJson(jsonb.decode(blobType.dartValue(databaseValue)));
    } else {
      return DatabaseJson(json.decode(textType.dartValue(databaseValue)));
    }
  }
}

/// A drift type around a SQL value with an unknown type.
///
/// In [STRICT tables], a column can be declared with the type `ANY`. In such
/// column, _any_ value can be stored without sqlite3 (or drift) attempting to
/// cast it to a specific type. Thus, the [fromDb] is directly passed to
/// or from the underlying SQL database package.
///
/// To write a custom value into the database with [DriftAny], you can construct
/// it and pass it into a [Variable] or into a companion of a table having a
/// column with an `ANY` type.
///
/// [STRICT tables]: https://www.sqlite.org/stricttables.html
extension type const DriftAny(Object fromDb) implements Object {
  /// Interprets the [fromDb] value as a drift [type] under the configuration
  /// given by the [DriftDialect].
  ///
  /// A given [fromDb] may have different Dart representations that would
  /// be given to you by drift. For instance, the SQL value `1` could have the
  /// following possible Dart interpretations:
  ///
  ///   - The [bool] constant `true`.
  ///   - The [int] constant `1`
  ///   - The big integer [BigInt.one].
  ///   - All [DateTime] values having `1` as their UNIX timestamp in seconds
  ///     (this depends on the configuration - drift can be configured to store
  ///     date times [as text] too).
  ///
  /// For this reason, it is not always possible to directly map these raw
  /// values to Dart without further information. Drift also needs to know the
  /// expected type and some configuration options for context. For all SQL
  /// types _except_ `ANY`, drift will do this for you behind the scenes.
  ///
  /// You can obtain a [dialect] instance from a database or DAO by using
  /// [DatabaseConnectionUser.dialect].
  /// For [type], enum values of [BuiltinDriftType] are most commonly used.
  ///
  /// [as text]: https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#datetime-options
  T readAs<T extends Object>(SqlType<T> type, DriftDialect dialect) {
    return type.resolveIn(dialect).dartValue(fromDb);
  }
}

/// The [SqlType] implementation for [DriftAny].
final class AnyType extends _SqliteType<DriftAny> {
  /// Default const constructor.
  const AnyType() : super('ANY');

  @override
  String sqlLiteral(DriftAny value) {
    return switch (value.fromDb) {
      final String s => textType.sqlLiteral(s),
      final Uint8List blob => blobType.sqlLiteral(blob),
      _ => value.toString(),
    };
  }

  @override
  Object? sqlParameter(DriftAny? value) {
    if (value == null) return null;

    return value.fromDb;
  }

  @override
  DriftAny dartValue(Object databaseValue) {
    return DriftAny(databaseValue);
  }
}
