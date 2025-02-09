import 'dialect.dart';
import 'expressions/expression.dart';
import 'expressions/variable.dart';
import 'results.dart';
import 'schema/column.dart';
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
}

abstract class SqlComponent {
  final Map<Symbol, Object?> dialectSpecificOptions = {};

  void compileWith(StatementCompiler compiler);
}

abstract base class StatementCompiler {
  late final CompiledStatement statement = CompiledStatement(dialect);

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
    addReference(reference.resultSet.name);
    if (reference.resultSet.alias case final alias?) {
      statement.buffer.write(' AS ');
      addReference(alias);
    }
  }

  void addSelectStatement(BaseSelectStatement select) {
    statement.buffer.write('SELECT ');

    if (select is SingleTableSelectStatement) {
      statement.buffer.write('*');
    } else {
      select.structure.expressions.forEach((expr, position) {
        expr.compileWith(this);
        statement.buffer.write(' AS ');
        addReference(position.name);
      });
    }

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

  void addColumnReference(SchemaColumn column) {
    if (statement.hasMultipleTables) {
      final resultSet = column.owningResultSet;
      addReference(resultSet.alias ?? resultSet.name);
      statement.buffer.write('.');
    }

    addReference(column.name);
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
}
