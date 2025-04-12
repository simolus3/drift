import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'dialect.dart';
import 'statements.dart';
import 'types.dart';

@internal
final class SqliteCompiler extends StatementCompiler {
  @override
  final SqliteDialect dialect;

  SqliteCompiler(this.dialect);

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

  @override
  void addInsertStatementMode(
      InsertStatement<Object, GeneratedTable<Object, dynamic>> insert) {
    final mode =
        insert.dialectSpecificOptions[insertModeKey] ?? InsertMode.insert;
    statement.buffer
      ..write(_insertKeywords[mode])
      ..write(' INTO');
  }
}

/// The key used for [DialectSpecificComponent.dialectSpecificOptions] to set
/// the [InsertMode] on [InsertStatement]s.
@internal
const insertModeKey = Symbol('drift.dialect.sqlite3.insert.mode');

const _insertKeywords = <InsertMode, String>{
  InsertMode.insert: 'INSERT',
  InsertMode.replace: 'REPLACE',
  InsertMode.insertOrReplace: 'INSERT OR REPLACE',
  InsertMode.insertOrRollback: 'INSERT OR ROLLBACK',
  InsertMode.insertOrAbort: 'INSERT OR ABORT',
  InsertMode.insertOrFail: 'INSERT OR FAIL',
  InsertMode.insertOrIgnore: 'INSERT OR IGNORE',
};
