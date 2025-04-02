import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/src/query_builder/expressions/datetime.dart';
import 'package:meta/meta.dart';

import 'types.dart';

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

  const SqliteDialect({this.options = const SqliteOptions()});

  @override
  KnownSqlDialect? get known => KnownSqlDialect.sqlite;

  @override
  StatementCompiler createCompiler() => _SqliteCompiler(this);

  @override
  SqlType<bool> get boolType => const BoolType();

  @override
  SqlType<Uint8List> get byteArrayType => const BlobType();

  @override
  SqlType<DateTime> get dateTimeType => const DateTimeType();

  @override
  SqlType<double> get doubleType => const DoubleType();

  @override
  SqlType<int> get intType => const IntType();

  @override
  SqlType<BigInt> get int64Type => const BigIntType();

  @override
  SqlType<DatabaseJson> get jsonType => const JsonType();

  @override
  SqlType<String> get textType => const StringType();

  /// Returns an implementation of [SqlType] that reads and writes [DriftAny]
  /// values without any further mapping.
  static SqlType<DriftAny> anyType() => const AnyType();
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

  @override
  void addCreateTableStatement(CreateTableStatement stmt) {
    super.addCreateTableStatement(stmt);

    final table = stmt.entity;
    final options = [
      if (table.withoutRowId) 'WITHOUT ROWID',
      if (table.isStrict) 'STRICT'
    ].join(', ');

    if (options.isNotEmpty) {
      statement.buffer
        ..write(' ')
        ..write(options);
    }
  }

  bool _needsToMakeDateTimeComparable(Expression inner) {
    return dialect.options.storeDateTimesAsText &&
        inner.resolveType(dialect) is DateTimeType;
  }

  Expression<double> _makeDateTimeComparable(Expression inner) {
    // When we're storing date time values as text, comparison operators need to
    // use the julianday() format to be comparable.
    return FunctionCallExpression('julianday', [inner]);
  }

  @override
  void addBinaryExpression(BinaryExpression<Object> expr) {
    if (expr.precedence == Precedence.comparison &&
        _needsToMakeDateTimeComparable(expr.left)) {
      return super.addBinaryExpression(BinaryExpression(
        _makeDateTimeComparable(expr.left),
        expr.operator,
        _makeDateTimeComparable(expr.right),
      ));
    }

    super.addBinaryExpression(expr);
  }

  @override
  void addBetweenExpression(BetweenExpression expression) {
    if (_needsToMakeDateTimeComparable(expression.target)) {
      return super.addBetweenExpression(
        _makeDateTimeComparable(expression.target).isBetween(
          _makeDateTimeComparable(expression.lower),
          _makeDateTimeComparable(expression.higher),
          not: expression.not,
        ),
      );
    }

    super.addBetweenExpression(expression);
  }

  @override
  void addCurrentDateOrTimeExpression(CurrentDateOrTimeExpression e) {
    if (!dialect.options.storeDateTimesAsText) {
      final literal = e.includeTime ? 'CURRENT_TIMESTAMP' : 'CURRENT_TIME';
      statement.buffer.write("CAST(strftime('%s',$literal) AS INTEGER)");
    } else {
      return super.addCurrentDateOrTimeExpression(e);
    }
  }

  @override
  void addUnixTimestampToDateTime(UnixTimestampToDateTime e) {
    if (dialect.options.storeDateTimesAsText) {
      FunctionCallExpression(
              'datetime', [e.timestamp, Literal<String>('unixepoch')])
          .compileWith(this);
    } else {
      // We're already using unix timestamps as our representation for dates.
      e.timestamp.compileWith(this);
    }
  }

  @override
  void addDateExtractionOperator(DateExtractionOperator<Object> e) {
    final storingAsText = dialect.options.storeDateTimesAsText;
    if (e.field == DateExtractionField.unixepoch) {
      if (storingAsText) {
        return FunctionCallExpression('UNIXEPOCH', [e.value]).compileWith(this);
      } else {
        // Already represented as the target value
        return e.value.compileWith(this);
      }
    }

    const simpleOperators = {
      DateExtractionField.year: '%Y',
      DateExtractionField.month: '%m',
      DateExtractionField.day: '%d',
      DateExtractionField.hour: '%H',
      DateExtractionField.minute: '%M',
      DateExtractionField.second: '%S',
    };

    if (simpleOperators[e.field] case final operator?) {
      statement.buffer.write("CAST(strftime('$operator', ");
      e.value.compileWith(this);

      if (!storingAsText) {
        statement.buffer.write(", 'unixepoch'");
      }
      statement.buffer.write(') AS INTEGER)');
      return;
    }

    const functionNames = {
      DateExtractionField.date: 'DATE',
      DateExtractionField.time: 'TIME',
      DateExtractionField.datetime: 'DATETIME',
      DateExtractionField.julianday: 'JULIANDAY',
    };

    if (functionNames[e.field] case final function?) {
      return FunctionCallExpression(function, [
        e.value,
        if (!storingAsText) const Literal<String>('unixepoch')
      ]).compileWith(this);
    }

    throw UnsupportedError('Operator ${e.field}');
  }
}
