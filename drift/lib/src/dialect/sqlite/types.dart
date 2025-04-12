@internal
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart' show hex;
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' show jsonb;

import 'dialect.dart';

abstract base class _SqliteType<T extends Object> implements SqlType<T> {
  final String name;

  const _SqliteType(this.name);

  @override
  T dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue as T;
  }

  @override
  Object sqlParameter(DriftDialect dialect, T value) {
    return value;
  }

  @override
  String typeName(DriftDialect dialect) => name;
}

final class _SqlTypeWithoutMapping<T extends Object> extends _SqliteType<T> {
  const _SqlTypeWithoutMapping(super.name);

  @override
  String sqlLiteral(DriftDialect dialect, T value) {
    return value.toString();
  }
}

final class BlobType extends _SqliteType<Uint8List> {
  const BlobType() : super('BLOB');

  @override
  String sqlLiteral(DriftDialect dialect, Uint8List value) {
    final String hexString = hex.encode(value);
    return "x'$hexString'";
  }
}

final class BoolType extends _SqlTypeWithoutMapping<bool> {
  const BoolType() : super('BOOLEAN');

  @override
  bool dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue != 0 && databaseValue != false;
  }

  @override
  Object sqlParameter(DriftDialect dialect, bool value) {
    return value ? 1 : 0;
  }

  @override
  String sqlLiteral(DriftDialect dialect, bool value) {
    return value ? '1' : '0';
  }
}

final class DoubleType extends _SqlTypeWithoutMapping<double> {
  const DoubleType() : super('REAL');

  @override
  double dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      BigInt() => databaseValue.toDouble(),
      _ => (databaseValue as num).toDouble(),
    };
  }
}

final class IntType extends _SqlTypeWithoutMapping<int> {
  const IntType() : super('INTEGER');

  @override
  int dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      int() => databaseValue,
      BigInt() => databaseValue.toInt(),
      double() => databaseValue.toInt(),
      _ => int.parse(databaseValue.toString()),
    };
  }
}

final class BigIntType extends _SqlTypeWithoutMapping<BigInt> {
  const BigIntType() : super('INTEGER');

  @override
  BigInt dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      int() => BigInt.from(databaseValue),
      BigInt() => databaseValue,
      double() => BigInt.from(databaseValue.toInt()),
      _ => BigInt.parse(databaseValue.toString()),
    };
  }
}

final class DateTimeType extends _SqliteType<DateTime> {
  const DateTimeType() : super('TEXT');

  bool _dateTimesAsText(DriftDialect dialect) {
    return (dialect as SqliteDialect).options.storeDateTimesAsText;
  }

  @override
  DateTime dartValue(DriftDialect dialect, Object databaseValue) {
    if (_dateTimesAsText(dialect)) {
      return DateTime.parse(databaseValue.toString());
    } else {
      return DateTime.fromMillisecondsSinceEpoch(
          1000 * const IntType().dartValue(dialect, databaseValue));
    }
  }

  @override
  Object sqlParameter(DriftDialect dialect, DateTime value) {
    if (_dateTimesAsText(dialect)) {
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

        return '${value.toIso8601String()}$prefix$formattedOffset';
      }
    } else {
      return value.millisecondsSinceEpoch ~/ 1000;
    }
  }

  @override
  String sqlLiteral(DriftDialect dialect, DateTime value) {
    final param = sqlParameter(dialect, value);
    return switch (param) {
      String s => "'$s'",
      final other => other.toString(),
    };
  }

  @override
  String typeName(DriftDialect dialect) {
    return _dateTimesAsText(dialect) ? 'TEXT' : 'INTEGER';
  }
}

final class JsonType extends _SqliteType<DatabaseJson> {
  const JsonType() : super('BLOB');

  bool _useBinary(DriftDialect dialect) {
    return (dialect as SqliteDialect).options.useBinaryJsonRepresentation;
  }

  @override
  String sqlLiteral(DriftDialect dialect, DatabaseJson value) {
    final binary = _useBinary(dialect);
    if (binary) {
      return const BlobType()
          .sqlLiteral(dialect, jsonb.encode(value.dartValue));
    } else {
      return const StringType()
          .sqlLiteral(dialect, json.encode(value.dartValue));
    }
  }

  @override
  Object sqlParameter(DriftDialect dialect, DatabaseJson value) {
    if (_useBinary(dialect)) {
      return jsonb.encode(value.dartValue);
    } else {
      return json.encode(value.dartValue);
    }
  }

  @override
  DatabaseJson dartValue(DriftDialect dialect, Object databaseValue) {
    if (_useBinary(dialect)) {
      return DatabaseJson(
          jsonb.decode(const BlobType().dartValue(dialect, databaseValue)));
    } else {
      return DatabaseJson(
          json.decode(const StringType().dartValue(dialect, databaseValue)));
    }
  }

  @override
  String typeName(DriftDialect dialect) {
    return _useBinary(dialect) ? 'BLOB' : 'TEXT';
  }
}

final class StringType extends _SqliteType<String> {
  const StringType() : super('TEXT');

  @override
  String dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue.toString();
  }

  @override
  String sqlLiteral(DriftDialect dialect, String value) {
    // From the sqlite docs: (https://www.sqlite.org/lang_expr.html)
    // A string constant is formed by enclosing the string in single quotes
    // (').
    // A single quote within the string can be encoded by putting two single
    // quotes in a row - as in Pascal. C-style escapes using the backslash
    // character are not supported because they are not standard SQL.
    final escapedChars = value.replaceAll('\'', '\'\'');
    return "'$escapedChars'";
  }
}

extension type DriftAny(Object fromDb) implements Object {}

final class AnyType extends _SqliteType<DriftAny> {
  const AnyType() : super('ANY');

  @override
  String sqlLiteral(DriftDialect dialect, DriftAny value) {
    throw 'TODO';
  }

  @override
  Object sqlParameter(DriftDialect dialect, DriftAny value) {
    return value.fromDb;
  }

  @override
  DriftAny dartValue(DriftDialect dialect, Object databaseValue) {
    return DriftAny(databaseValue);
  }
}
