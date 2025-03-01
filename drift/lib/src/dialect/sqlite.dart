import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' show jsonb;

import '../dsl/columns.dart';
import '../dsl/table.dart';
import '../query_builder.dart';
import '../query_builder/compiler.dart';
import '../query_builder/dialect.dart';
import '../query_builder/schema/column.dart';
import '../query_builder/types.dart';

extension DriftAnyColumnBuilder on Table {
  /// Use this as a the body of a getter to declare a column that holds
  /// arbitrary values not modified by drift at runtime.
  ///
  /// The type of this column in the schema is `ANY`, which is particularly
  /// useful for columns with an unknown type in [isStrict] tables.
  /// This type has no direct equivalent for other database engines.
  @protected
  @DriftColumnDeclarationBuilder.forCustom(SqliteDialect.anyType)
  ColumnBuilder<DriftAny> sqliteAny() => throw '';
}

/// A column storing arbitrary values using SQLite's `ANY` type.
typedef AnyColumn = SchemaColumn<DriftAny>;

final class SqliteOptions {
  final bool strictTablesByDefault;
  final bool storeDateTimesAsText;
  final bool useBinaryJsonRepresentation;

  const SqliteOptions({
    this.strictTablesByDefault = true,
    this.storeDateTimesAsText = true,
    this.useBinaryJsonRepresentation = false,
  });
}

final class SqliteDialect extends DriftDialect {
  final SqliteOptions options;

  SqliteDialect({this.options = const SqliteOptions()});

  @override
  StatementCompiler createCompiler() => _SqliteCompiler(this);

  @override
  SqlType<bool> get boolType => const _BoolType();

  @override
  SqlType<Uint8List> get byteArrayType => const _BlobType();

  @override
  SqlType<DateTime> get dateTimeType => const _DateTimeType();

  @override
  SqlType<double> get doubleType => const _DoubleType();

  @override
  SqlType<int> get intType => const _IntType();

  @override
  SqlType<BigInt> get int64Type => const _BigIntType();

  @override
  SqlType<DatabaseJson> get jsonType => const _JsonType();

  @override
  SqlType<String> get textType => const _StringType();

  static SqlType<DriftAny> anyType() => const _AnyType();
}

final class _SqliteCompiler extends StatementCompiler {
  @override
  final SqliteDialect dialect;

  _SqliteCompiler(this.dialect);

  @override
  void addPositionalVariable(int index) {
    statement.buffer
      ..write('?')
      ..write(index);
  }
}

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

final class _BlobType extends _SqliteType<Uint8List> {
  const _BlobType() : super('BLOB');

  @override
  String sqlLiteral(DriftDialect dialect, Uint8List value) {
    final String hexString = hex.encode(value);
    return "x'$hexString'";
  }
}

final class _BoolType extends _SqlTypeWithoutMapping<bool> {
  const _BoolType() : super('BOOLEAN');

  @override
  bool dartValue(DriftDialect dialect, Object databaseValue) {
    return databaseValue != 0 && databaseValue != false;
  }
}

final class _DoubleType extends _SqlTypeWithoutMapping<double> {
  const _DoubleType() : super('REAL');

  @override
  double dartValue(DriftDialect dialect, Object databaseValue) {
    return switch (databaseValue) {
      BigInt() => databaseValue.toDouble(),
      _ => (databaseValue as num).toDouble(),
    };
  }
}

final class _IntType extends _SqlTypeWithoutMapping<int> {
  const _IntType() : super('INTEGER');

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

final class _BigIntType extends _SqlTypeWithoutMapping<BigInt> {
  const _BigIntType() : super('INTEGER');

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

final class _DateTimeType extends _SqliteType<DateTime> {
  const _DateTimeType() : super('TEXT');

  bool _dateTimesAsText(DriftDialect dialect) {
    return (dialect as SqliteDialect).options.storeDateTimesAsText;
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

final class _JsonType extends _SqliteType<DatabaseJson> {
  const _JsonType() : super('BLOB');

  bool _useBinary(DriftDialect dialect) {
    return (dialect as SqliteDialect).options.useBinaryJsonRepresentation;
  }

  @override
  String sqlLiteral(DriftDialect dialect, DatabaseJson value) {
    final binary = _useBinary(dialect);
    if (binary) {
      return const _BlobType()
          .sqlLiteral(dialect, jsonb.encode(value.dartValue));
    } else {
      return const _StringType()
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
          jsonb.decode(const _BlobType().dartValue(dialect, databaseValue)));
    } else {
      return DatabaseJson(
          json.decode(const _StringType().dartValue(dialect, databaseValue)));
    }
  }

  @override
  String typeName(DriftDialect dialect) {
    return _useBinary(dialect) ? 'BLOB' : 'TEXT';
  }
}

final class _StringType extends _SqliteType<String> {
  const _StringType() : super('TEXT');

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

final class _AnyType extends _SqliteType<DriftAny> {
  const _AnyType() : super('ANY');

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

extension SqliteSpecificStringOperators on Expression<String> {
  /// Matches this string against the regular expression in [regex].
  ///
  /// The [multiLine], [caseSensitive], [unicode] and [dotAll] parameters
  /// correspond to the parameters on [RegExp].
  ///
  /// Note that this function is only available when using a `NativeDatabase`.
  /// If you need to support the web or `moor_flutter`, consider using [like]
  /// instead.
  Expression<bool> regexp(
    String regex, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    // We have a special regexp sql function that takes a third parameter
    // to encode flags. If the least significant bit is set, multiLine is
    // enabled. The next three bits enable case INSENSITIVITY (it's sensitive
    // by default), unicode and dotAll.
    var flags = 0;

    if (multiLine) {
      flags |= 1;
    }
    if (!caseSensitive) {
      flags |= 2;
    }
    if (unicode) {
      flags |= 4;
    }
    if (dotAll) {
      flags |= 8;
    }

    if (flags != 0) {
      return FunctionCallExpression<bool>(
        'regexp_moor_ffi',
        [
          Variable.withString(regex),
          this,
          Variable.withInt(flags),
        ],
      );
    }

    // No special flags enabled, use the regular REGEXP operator
    return BinaryExpression(
        this, BinaryOperator.regexp, Variable.withString(regex));
  }
}
