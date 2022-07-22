import 'dart:core';
import 'dart:core' as core;
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:meta/meta.dart';

import '../query_builder/query_builder.dart';

/// Static helper methods mapping Dart values from and to SQL variables or
/// literals.
@sealed
class SqlTypes {
  // Stolen from DateTime._parseFormat
  static final RegExp _timeZoneInDateTime =
      RegExp(r' ?([-+])(\d\d)(?::?(\d\d))?$');

  /// Whether these type mappings have been configured to store date time values
  /// as text.
  ///
  /// When false (the default), date times values are stored as unix timestamps
  /// with second accuracy. When true, date time values are stored as an
  /// ISO-8601 string.
  final bool storeDateTimesAsText;

  /// Creates an [SqlTypes] mapper from the provided options.
  @internal
  const SqlTypes(this.storeDateTimesAsText);

  /// Maps a Dart object to a (possibly simpler) object that can be used as a
  /// parameter in raw sql queries.
  Object? mapToSqlVariable(Object? dartValue) {
    if (dartValue == null) return null;

    // These need special handling, all other types are a direct mapping
    if (dartValue is DateTime) {
      if (storeDateTimesAsText) {
        // sqlite3 assumes UTC by default, so we store the explicit UTC offset
        // along with the value. For UTC datetimes, there's nothing to change
        if (dartValue.isUtc) {
          return dartValue.toIso8601String();
        } else {
          final offset = dartValue.timeZoneOffset;
          // Quick sanity check: We can only store the UTC offset as `hh:mm`,
          // so if the offset has seconds for some reason we should refuse to
          // store that.
          if (offset.inSeconds - 60 * offset.inMinutes != 0) {
            throw ArgumentError.value(dartValue, 'dartValue',
                'Cannot be mapped to SQL: Invalid UTC offset $offset');
          }

          final hours = offset.inHours.abs();
          final minutes = offset.inMinutes.abs() - 60 * hours;

          // For local date times, add the offset as ` +hh:mm` in the end. This
          // format is understood by `DateTime.parse` and date time functions in
          // sqlite.
          final prefix = offset.isNegative ? ' -' : ' +';
          final formattedOffset = '${hours.toString().padLeft(2, '0')}:'
              '${minutes.toString().padLeft(2, '0')}';

          return '${dartValue.toIso8601String()}$prefix$formattedOffset';
        }
      } else {
        return dartValue.millisecondsSinceEpoch ~/ 1000;
      }
    }

    if (dartValue is bool) {
      return dartValue ? 1 : 0;
    }

    return dartValue;
  }

  /// Maps the [dart] value into a SQL literal that can be embedded in SQL
  /// queries.
  String mapToSqlLiteral(Object? dart) {
    if (dart == null) return 'NULL';

    // todo: Inline and remove types in the next major drift version
    if (dart is bool) {
      return dart ? '1' : '0';
    } else if (dart is String) {
      // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
      // A string constant is formed by enclosing the string in single quotes
      // (').
      // A single quote within the string can be encoded by putting two single
      // quotes in a row - as in Pascal. C-style escapes using the backslash
      // character are not supported because they are not standard SQL.
      final escapedChars = dart.replaceAll('\'', '\'\'');
      return "'$escapedChars'";
    } else if (dart is num || dart is BigInt) {
      return dart.toString();
    } else if (dart is DateTime) {
      if (storeDateTimesAsText) {
        final encoded = mapToSqlVariable(dart).toString();
        return "'$encoded'";
      } else {
        return (dart.millisecondsSinceEpoch ~/ 1000).toString();
      }
    } else if (dart is Uint8List) {
      // BLOB literals are string literals containing hexadecimal data and
      // preceded by a single "x" or "X" character. Example: X'53514C697465'
      return "x'${hex.encode(dart)}'";
    }

    throw ArgumentError.value(dart, 'dart',
        'Must be null, bool, String, int, DateTime, Uint8List or double');
  }

  /// Maps a raw [sqlValue] to Dart given its sql [type].
  T? read<T extends Object>(DriftSqlType<T> type, Object? sqlValue) {
    if (sqlValue == null) return null;

    // ignore: unnecessary_cast
    switch (type as DriftSqlType<Object>) {
      case DriftSqlType.bool:
        return (sqlValue != 0) as T;
      case DriftSqlType.string:
        return sqlValue.toString() as T;
      case DriftSqlType.bigInt:
        if (sqlValue is BigInt) return sqlValue as T?;
        if (sqlValue is int) return BigInt.from(sqlValue) as T;
        return BigInt.parse(sqlValue.toString()) as T;
      case DriftSqlType.int:
        if (sqlValue is int) return sqlValue as T;
        if (sqlValue is BigInt) return sqlValue.toInt() as T;
        return int.parse(sqlValue.toString()) as T;
      case DriftSqlType.dateTime:
        if (storeDateTimesAsText) {
          final rawValue = read(DriftSqlType.string, sqlValue)!;
          final value = DateTime.parse(rawValue);

          // The stored format is the same as toIso8601String for utc values,
          // but for local date times we append the time zone offset.
          // DateTime.parse picks that up, but then returns an UTC value. For
          // round-trip equality, we recover that information and reutrn to
          // a local date time.
          if (_timeZoneInDateTime.hasMatch(rawValue)) {
            return value.toLocal() as T;
          } else {
            return value as T;
          }
        } else {
          final unixSeconds = read(DriftSqlType.int, sqlValue)!;
          return DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000) as T;
        }
      case DriftSqlType.blob:
        if (sqlValue is String) {
          final list = sqlValue.codeUnits;
          return Uint8List.fromList(list) as T;
        }
        return sqlValue as T;
      case DriftSqlType.double:
        return (sqlValue as num?)?.toDouble() as T;
    }
  }
}

/// An enumation of type mappings that are builtin to drift and `drift_dev`.
enum DriftSqlType<T extends Object> {
  /// A boolean type, represented as `0` or `1` (int) in SQL.
  bool<core.bool>(),

  /// A textual type, represented as `TEXT` in sqlite.
  string<String>(),

  /// A 64-bit int type that is represented a [BigInt] in Dart for better
  /// compatibility with the web. Represented as an `INTEGER` in sqlite or as
  /// a `bigint` in postgres.
  bigInt<BigInt>(),

  /// A 64-bit int.
  ///
  /// Represented as an `INTEGER` in sqlite or as a `bigint` in postgres.
  int<core.int>(),

  /// A [DateTime] value.
  ///
  /// Depending on the options choosen at build-time, this is either stored as
  /// an unix timestamp (the default) or as a ISO 8601 string.
  dateTime<DateTime>(),

  /// A [Uint8List] value.
  ///
  /// This is stored as a `BLOB` in sqlite or as a `bytea` type in postgres.
  blob<Uint8List>(),

  /// A [double] value, stored as a `REAL` type in sqlite.
  double<core.double>();

  /// Returns a suitable representation of this type in SQL.
  String sqlTypeName(GenerationContext context) {
    final dialect = context.dialect;

    // ignore: unnecessary_cast
    switch (this as DriftSqlType<Object>) {
      case DriftSqlType.bool:
        return dialect == SqlDialect.sqlite ? 'INTEGER' : 'integer';
      case DriftSqlType.string:
        return dialect == SqlDialect.sqlite ? 'TEXT' : 'text';
      case DriftSqlType.bigInt:
      case DriftSqlType.int:
        return dialect == SqlDialect.sqlite ? 'INTEGER' : 'bigint';
      case DriftSqlType.dateTime:
        if (context.options.types.storeDateTimesAsText) {
          return dialect == SqlDialect.sqlite ? 'TEXT' : 'text';
        } else {
          return dialect == SqlDialect.sqlite ? 'INTEGER' : 'bigint';
        }
      case DriftSqlType.blob:
        return dialect == SqlDialect.sqlite ? 'BLOB' : 'bytea';
      case DriftSqlType.double:
        return dialect == SqlDialect.sqlite ? 'REAL' : 'float8';
    }
  }

  /// Attempts to find a suitable SQL type for the [Dart] type passed to this
  /// method.
  ///
  /// The [Dart] type must be the type of the instance _after_ applying type
  /// converters.
  static DriftSqlType<Dart> forType<Dart extends Object>() {
    for (final type in values) {
      if (type is DriftSqlType<Dart>) return type;
    }

    throw ArgumentError('Could not find a matching SQL type for $Dart');
  }
}
