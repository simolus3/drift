import 'clauses/order_by.dart';
import 'clauses/where.dart';
import 'dialect.dart';
import 'expressions/aggregate.dart';
import 'expressions/case_when.dart';
import 'expressions/expression.dart';
import 'expressions/functions.dart';
import 'expressions/operators.dart';
import 'expressions/subquery.dart';
import 'expressions/tuple.dart';
import 'expressions/variables.dart';
import 'results.dart';
import 'schema/column.dart';
import 'schema/column_constraints.dart';
import 'statements/select.dart';
import 'statements/transactions.dart';
import 'types.dart';

final class CompiledStatement {
  final DriftDialect dialect;
  final StringBuffer buffer = StringBuffer();

  final List<TypedNullableValue> variables = [];
  final Map<Variable, int> _variableIndexes = {};

  bool hasMultipleTables = false;

  ResultSetStructure? resultSetStructure;

  CompiledStatement(this.dialect);

  void space() => buffer.write(' ');

  void comma() => buffer.write(',');
}

/// Base class for anything that can be compiled to SQL.
abstract interface class SqlComponent {
  void compileWith(StatementCompiler compiler);
}

abstract mixin class DialectSpecificComponent implements SqlComponent {
  final Map<Symbol, Object?> dialectSpecificOptions = {};
}

final class CustomComponent implements SqlComponent {
  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCustom(this);
  }
}

abstract base class StatementCompiler {
  late final CompiledStatement statement = CompiledStatement(dialect);
  Precedence? _expressionPrecedence;

  DriftDialect get dialect;

  void addPositionalVariable(int index);

  void addExpression(Expression expression) {
    throw UnsupportedError('Unhandled expression: $expression');
  }

  void addReference(String name) {
    statement.buffer
      ..write('"')
      ..write(name)
      ..write('"');
  }

  void addVariable(Variable variable) {
    if (statement._variableIndexes[variable] case final index?) {
      addPositionalVariable(index);
    } else {
      final type = variable.resolveType(dialect);
      statement.variables.add((type, variable.value));
      final sqlIndex = statement.variables.length;
      statement._variableIndexes[variable] = sqlIndex;

      addPositionalVariable(sqlIndex);
    }
  }

  void addTableReference(TableReference reference) {
    addReference(reference.resultSet.entityName);
    if (reference.resultSet.alias case final alias?) {
      statement.buffer.write(' AS ');
      addReference(alias);
    }
  }

  void addJoin(Join join) {}

  void addJoinOperator(JoinOperator operator) {
    statement.buffer.write(operator.defaultLexeme);
  }

  void addSelectStatement(BaseSelectStatement select) {
    statement.buffer.write('SELECT ');

    var first = true;
    select.structure.expressions.forEach((expr, position) {
      if (!first) {
        statement.comma();
      }
      first = false;

      expr.compileWith(this);
      statement.buffer.write(' AS ');
      addReference(position.name);
    });
    statement.resultSetStructure = select.structure;

    if (select.from case [final first, ...final rest]) {
      statement.buffer.write(' FROM ');
      first.compileWith(this);

      for (final entry in rest) {
        // TODO: No comma necessary for join
        statement.buffer.write(', ');
        entry.compileWith(this);
      }
    }
  }

  void addCaseWhenExpression(CaseWhenExpression expr) {
    statement.buffer.write('CASE');

    if (expr.base case final base?) {
      statement.buffer.write(' ');
      base.compileWith(this);
    }

    for (final (when: condition, :then) in expr.orderedCases) {
      statement.buffer.write(' WHEN ');
      condition.compileWith(this);
      statement.buffer.write(' THEN ');
      then.compileWith(this);
    }

    if (expr.orElse case final orElse?) {
      statement.buffer.write(' ELSE ');
      orElse.compileWith(this);
    }

    statement.buffer.write(' END');
  }

  void addCastExpression(CastExpression expr) {
    writeExpression(expr, () {
      statement.buffer.write('CAST(');
      expr.inner.compileWith(this);
      statement.buffer.write(' AS ');
      addTypeName(expr.resolveType(dialect));
      statement.buffer.write(')');
    });
  }

  void addTypeName(SqlType type) {
    statement.buffer.write(type.typeName(dialect));
  }

  void addTuple(ExpressionTuple tuple) {
    statement.buffer.write('(');
    addCommaSeparated(tuple.values);
    statement.buffer.write(')');
  }

  void addSubqueryExpression(SubqueryExpression e) {
    if (e.statement.structure.expressions.length != 1) {
      throw StateError(
          'Error compiling subquery expression $e, inner query must have exactly one column.');
    }

    statement.buffer.write('(');
    e.statement.compileWith(this);
    statement.buffer.write(')');
  }

  void addColumnReference(SchemaColumn column) {
    if (statement.hasMultipleTables) {
      final resultSet = column.owningResultSet;
      addReference(resultSet.aliasOrName);
      statement.buffer.write('.');
    }

    addReference(column.name);
  }

  void addWhereClause(WhereClause where) {
    statement.buffer.write('WHERE ');
    where.condition.compileWith(this);
  }

  void addStarFunctionParameter(StarFunctionParameter parameter) {
    statement.buffer.write('*');
  }

  void addCommaSeparated(Iterable<SqlComponent> components) {
    var first = true;
    for (final arg in components) {
      if (!first) {
        statement.comma();
      }
      first = false;

      arg.compileWith(this);
    }
  }

  void addAggregateFunctionExpression(AggregateFunctionExpression expr) {
    writeExpression(expr, () {
      addFunctionName(expr, expr.functionName);
      statement.buffer.write('(');
      if (expr.distinct) {
        statement.buffer.write('DISTINCT ');
      }
      addCommaSeparated(expr.arguments);
      if (expr.orderBy case final orderBy?) {
        statement.space();
        orderBy.compileWith(this);
      }
      statement.buffer.write(')');

      if (expr.filter case final filter?) {
        statement.buffer.write(' FILTER (');
        filter.compileWith(this);
        statement.buffer.write(')');
      }
    });
  }

  void addOrderBy(OrderBy orderBy) {
    throw 'todo';
  }

  void writeExpression(Expression expression, void Function() write) {
    final savedPrecedence = _expressionPrecedence;
    final needsParentheses =
        savedPrecedence != null && expression.precedence <= savedPrecedence;
    _expressionPrecedence = expression.precedence;
    if (needsParentheses) statement.buffer.write('(');
    write();
    if (needsParentheses) statement.buffer.write(')');
    _expressionPrecedence = savedPrecedence;
  }

  void addBinaryExpression(BinaryExpression expr) {
    writeExpression(expr, () {
      expr.left.compileWith(this);
      statement.space();
      addBinaryOperator(expr.operator);
      statement.space();
      expr.right.compileWith(this);
    });
  }

  void addUnaryExpression(UnaryExpression expr) {
    writeExpression(expr, () {
      if (expr.operator.isPrefix) {
        addUnaryOperator(expr.operator);
        statement.space();
        expr.compileWith(this);
      } else {
        expr.compileWith(this);
        statement.space();
        addUnaryOperator(expr.operator);
      }
    });
  }

  void addBinaryOperator(BinaryOperator operator) {
    statement.buffer.write(operator.defaultLexeme);
  }

  void addUnaryOperator(UnaryOperator operator) {
    statement.buffer.write(operator.defaultLexeme);
  }

  void addLiteral(Literal literal) {
    if (literal.value case final value?) {
      final type = literal.resolveType(dialect);
      statement.buffer.write(type.sqlLiteral(dialect, value));
    } else {
      statement.buffer.write('NULL');
    }
  }

  void addFunctionCallExpression(FunctionCallExpression expression) {
    writeExpression(expression, () {
      addFunctionName(expression, expression.functionName);
      statement.buffer.write('(');
      addCommaSeparated(expression.arguments);
      statement.buffer.write(')');
    });
  }

  void addFunctionName(Expression call, String name) {
    statement.buffer.write(name);
  }

  /// Write a [BeginStatement] statement.
  void addBegin(BeginStatement stmt) {
    statement.buffer
        .write(stmt.depth == 0 ? 'BEGIN;' : 'SAVEPOINT s${stmt.depth};');
  }

  /// Write a [CommitStatement] statement.
  void addCommit(CommitStatement stmt) {
    statement.buffer
        .write(stmt.depth == 0 ? 'COMMIT;' : 'RELEASE s${stmt.depth};');
  }

  /// Write a [RollbackStatement] statement.
  void addRollback(RollbackStatement stmt) {
    statement.buffer.write('ROLLBACK');
    if (stmt.depth > 0) {
      statement.buffer.write(' TO ${stmt.depth}');
    }
    statement.buffer.write(';');
  }

  void addColumnPrimaryKeyConstraint(ColumnPrimaryKeyConstraint constraint) {
    statement.buffer.write('PRIMARY KEY');
    if (constraint.isAutoIncrementing) {
      statement.buffer.write(' AUTOINCREMENT');
    }
  }

  void addColumnGeneratedAs(ColumnGeneratedAs constraint) {
    statement.buffer.write('GENERATED ALWAYS AS (');
    constraint.generatedAs.compileWith(this);
    statement.buffer.write(')');
    statement.buffer.write(constraint.stored ? ' STORED' : ' VIRTUAL');
  }

  void addColumnUniqueConstraint(ColumnUniqueConstraint constraint) {
    statement.buffer.write('UNIQUE');
  }

  void addColumnForeignKeyConstraint(ColumnForeignKeyConstraint constraint) {
    statement.buffer.write(
        'REFERENCES ${constraint.otherTableName} (${constraint.otherColumnName})');
    if (constraint.onUpdate case final onUpdate?) {
      statement.buffer.write(' ON UPDATE ${onUpdate.defaultLexeme}');
    }
    if (constraint.onDelete case final onDelete?) {
      statement.buffer.write(' ON UPDATE ${onDelete.defaultLexeme}');
    }

    if (constraint.initiallyDeferred) {
      statement.buffer.write('INITIALLY DEFERRED');
    }
  }

  void addColumnCheckConstraint(ColumnCheckConstraint constraint) {
    statement.buffer.write('CHECK (');
    constraint.check.compileWith(this);
    statement.buffer.write(')');
  }

  void addCustom(CustomComponent component);
}
