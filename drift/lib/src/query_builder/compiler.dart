import 'package:collection/collection.dart';

import '../runtime/streams/update_rules.dart';
import 'clauses/group_by.dart';
import 'clauses/limit.dart';
import 'clauses/order_by.dart';
import 'clauses/returning.dart';
import 'clauses/where.dart';
import 'dialect.dart';
import 'expressions/aggregate.dart';
import 'expressions/case_when.dart';
import 'expressions/comparable.dart';
import 'expressions/datetime.dart';
import 'expressions/exists.dart';
import 'expressions/expression.dart';
import 'expressions/functions.dart';
import 'expressions/operators.dart';
import 'expressions/subquery.dart';
import 'expressions/text.dart';
import 'expressions/tuple.dart';
import 'expressions/variables.dart';
import 'results.dart';
import 'schema/column.dart';
import 'schema/column_constraints.dart';
import 'schema/drop.dart';
import 'schema/entities.dart';
import 'schema/result_set.dart';
import 'schema/subquery.dart';
import 'schema/table.dart';
import 'schema/view.dart';
import 'statements/delete.dart';
import 'statements/insert.dart';
import 'statements/select.dart';
import 'statements/transactions.dart';
import 'statements/update.dart';
import 'types.dart';

final class CompiledStatement {
  final DriftDialect dialect;
  final StringBuffer buffer = StringBuffer();

  final List<TypedNullableValue> variables = [];
  final Map<Variable, int> _variableIndexes = {};
  final Set<ResultSet> watchedTables = {};
  final Set<TableUpdate> possibleUpdates = {};
  bool isReadOnly = false;

  int variableOffset = 0;
  bool hasMultipleTables = false;
  bool supportsVariables = true;

  ResultSetStructure? resultSetStructure;

  int get amountOfVariables => variables.length;

  String get sql => buffer.toString();

  CompiledStatement(this.dialect);

  void space() => buffer.write(' ');

  void comma() => buffer.write(',');

  void semicolon() => buffer.write(';');
}

/// Base class for anything that can be compiled to SQL.
abstract interface class SqlComponent {
  void compileWith(StatementCompiler compiler);
}

abstract mixin class DialectSpecificComponent implements SqlComponent {
  final Map<Symbol, Object?> dialectSpecificOptions = {};
}

final class CustomComponent implements SqlComponent {
  final String fallbackSql;
  final Map<KnownSqlDialect, String> dialectSpecifcSql;

  /// Additional tables that this SQL construct is watching.
  ///
  /// When this component is used in a stream query, the stream will update
  /// when any table in [watchedTables] changes.
  /// Usually, custom components don't introduce new tables to watch. This field
  /// is mainly used for view and subqueries used as expressions.
  final Iterable<ResultSet> watchedTables;

  const CustomComponent(
    this.fallbackSql, {
    this.dialectSpecifcSql = const {},
    this.watchedTables = const [],
  });

  String sqlFor(KnownSqlDialect? dialect) {
    return dialectSpecifcSql[dialect] ?? fallbackSql;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCustom(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomComponent &&
        other.fallbackSql == fallbackSql &&
        _equality.equals(other.dialectSpecifcSql, dialectSpecifcSql);
  }

  @override
  int get hashCode =>
      Object.hash(fallbackSql, _equality.hash(dialectSpecifcSql));

  static const _equality = MapEquality<Object?, Object?>();
}

abstract base class StatementCompiler {
  late final CompiledStatement statement = CompiledStatement(dialect);
  Precedence? _expressionPrecedence;

  bool _ignoreResultSet = false;
  InsertStatement? _currentInsertStatement;

  DriftDialect get dialect;

  void addPositionalVariable(int index);

  void addExpression(Expression expression) {
    throw UnsupportedError('Unhandled expression: $expression');
  }

  void addTableColumnDefinition(TableColumn column) {
    addReference(column.name);
    statement.space();
    statement.buffer.write(column.type.typeName(dialect));
    statement.space();

    var hadConstraint = false;
    if (!column.isNullable) {
      hadConstraint = true;
      statement.buffer.write('NOT NULL');
    }

    for (final constraint in column.constraints) {
      if (constraint case CustomColumnConstraint(:final onlyOnDialect?)) {
        if (onlyOnDialect != dialect.known) {
          continue;
        }
      }

      if (hadConstraint) {
        statement.space();
      }

      constraint.compileWith(this);
      hadConstraint = true;
    }
  }

  void addAddColumnStatement(AddColumnStatement stmt) {
    statement.buffer.write('ALTER TABLE ');
    addReference(stmt.table.aliasOrName);
    statement.buffer.write(' ADD COLUMN ');
    addTableColumnDefinition(stmt.column);
    statement.buffer.write(';');
  }

  void addDropColumnStatement(DropColumnStatement stmt) {
    statement.buffer.write('ALTER TABLE ');
    addReference(stmt.table.aliasOrName);
    statement.buffer.write(' DROP COLUMN ');
    addReference(stmt.columnName);
    statement.buffer.write(';');
  }

  void addRenameColumnStatement(RenameColumnStatement stmt) {
    statement.buffer.write('ALTER TABLE ');
    addReference(stmt.table.aliasOrName);
    statement.buffer.write(' RENAME COLUMN ');
    addReference(stmt.oldName);
    statement.buffer.write(' TO ');
    addReference(stmt.column.name);
    statement.buffer.write(';');
  }

  void addRenameTableStatement(RenameTableStatement stmt) {
    statement.buffer.write('ALTER TABLE ');
    addReference(stmt.oldName);
    statement.buffer.write(' RENAME TO ');
    addReference(stmt.table.entityName);
    statement.buffer.write(';');
  }

  void addReference(String name) {
    statement.buffer
      ..write('"')
      ..write(name)
      ..write('"');
  }

  void addVariable(Variable variable) {
    if (!statement.supportsVariables) {
      return addLiteral(Literal(variable.value, variable.resolveType));
    }

    if (statement._variableIndexes[variable] case final index?) {
      addPositionalVariable(index);
    } else {
      statement.variables.add(variable.resolveValue(dialect));
      final sqlIndex = statement.variableOffset + statement.variables.length;
      statement._variableIndexes[variable] = sqlIndex;

      addPositionalVariable(sqlIndex);
    }
  }

  void addBetweenExpression(BetweenExpression expression) {
    writeExpression(expression, () {
      expression.target.compileWith(this);

      if (expression.not) statement.buffer.write(' NOT');
      statement.buffer.write(' BETWEEN ');

      expression.lower.compileWith(this);
      statement.buffer.write(' AND ');
      expression.higher.compileWith(this);
    });
  }

  void addFromResultSet(FromResultSet resultSet,
      {bool isWatching = true, UpdateKind? write}) {
    final resolved = resultSet.resultSet;
    if (resolved case final SqlComponent component) {
      return component.compileWith(this);
    }

    if (isWatching) {
      statement.watchedTables.add(resultSet.resultSet);
    }
    if (write != null && resolved is GeneratedTable) {
      statement.isReadOnly = false;
      statement.possibleUpdates.add(TableUpdate.onTable(resolved, kind: write));
    }

    addReference(resultSet.resultSet.entityName);
    if (resultSet.resultSet.alias case final alias?) {
      statement.buffer.write(' AS ');
      addReference(alias);
    }
  }

  void addCreateTableStatement(CreateTableStatement stmt) {
    statement.supportsVariables = false;
    final table = stmt.entity;
    statement.buffer.write('CREATE TABLE ');
    if (stmt.ifNotExists) {
      statement.buffer.write('IF NOT EXISTS ');
    }
    addReference(table.entityName);
    statement.buffer.write(' (');

    for (final (i, column) in table.columns.indexed) {
      if (i != 0) {
        statement.comma();
      }

      addTableColumnDefinition(column);
    }

    if (!table.dontWriteConstraints) {
      // TODO: Emit table constraints
    }

    final constraints = table.customConstraints;
    for (var i = 0; i < constraints.length; i++) {
      statement.buffer
        ..write(', ')
        ..write(constraints[i]);
    }

    statement.buffer.write(')');
    addTableModifiers(stmt);
    statement.buffer.write(';');
  }

  void addTableModifiers(CreateTableStatement stmt) {}

  void addCreateViewStatement(CreateViewStatement create) {
    final view = create.entity;
    if (view.sqlDefinition case final sql?) {
      sql.compileWith(this);
    } else {
      statement.supportsVariables = false;
      statement.buffer.write('CREATE VIEW ');
      if (create.ifNotExists) {
        statement.buffer.write('IF NOT EXISTS ');
      }

      addReference(view.entityName);
      statement.buffer.write('(');

      for (final (i, column) in view.columns.indexed) {
        if (i != 0) statement.comma();

        addReference(column.name);
      }

      statement.buffer.write(') AS ');
      view.query!.compileWith(this);
    }
  }

  void addCreateIndexStatement(CreateIndexStatement statement) {
    statement.entity.definition.compileWith(this);
  }

  void addCreateTriggerStatement(CreateTriggerStatement statement) {
    statement.entity.definition.compileWith(this);
  }

  void addDropStatement(DropStatement stmt) {
    statement.buffer
      ..write('DROP ')
      ..write(stmt.kind)
      ..write(' IF EXISTS ');
    addReference(stmt.name);
    statement.buffer.write(';');
  }

  void addJoin(Join join) {
    join.operator.compileWith(this);
    statement.space();
    join.table.compileWith(this);
    if (join.on case final on?) {
      statement.buffer.write(' ON ');
      on.compileWith(this);
    }
  }

  void addJoinOperator(JoinOperator operator) {
    statement.buffer.write(operator.defaultLexeme);
  }

  void addDeleteStatement(DeleteStatement delete) {
    statement.buffer.write('DELETE FROM ');
    addFromResultSet(FromResultSet(delete.resultSet),
        isWatching: false, write: UpdateKind.delete);

    if (delete.whereClause case final where?) {
      statement.space();
      where.compileWith(this);
    }

    if (delete.returning case final returning?) {
      statement.resultSetStructure = returning.structure;
      statement.space();
      returning.compileWith(this);
    }
    statement.buffer.write(';');
  }

  void addUpdateStatement(UpdateStatement update) {
    statement.buffer.write('UPDATE ');
    addFromResultSet(FromResultSet(update.resultSet),
        isWatching: false, write: UpdateKind.update);
    statement.buffer.write(' SET ');

    var first = true;
    update.updatedColumns.forEach((name, variable) {
      if (!first) {
        statement.comma();
      } else {
        first = false;
      }

      addReference(name);
      statement.buffer.write(' = ');
      variable.compileWith(this);
    });

    if (update.whereClause case final where?) {
      statement.space();
      where.compileWith(this);
    }

    if (update.returning case final returning?) {
      statement.resultSetStructure = returning.structure;
      statement.space();
      returning.compileWith(this);
    }
    statement.buffer.write(';');
  }

  void addInsertStatementMode(InsertStatement insert) {
    statement.buffer.write('INSERT INTO');
  }

  void addInsertColumnNames(InsertStatement insert) {
    switch (insert.source) {
      case null:
      case InsertDefaultValues():
        return;
      case InsertFromValues fromValues:
        statement.buffer.write('(');
        for (final (i, entry) in fromValues.values.keys.indexed) {
          if (i != 0) statement.comma();
          addReference(entry);
        }
        statement.buffer.write(')');
        statement.space();
      case InsertFromSelect fromSelect:
        statement.buffer.write('(');
        for (final (i, entry)
            in fromSelect.columnNameToSelectColumnName.keys.indexed) {
          if (i != 0) statement.comma();
          addReference(entry);
        }
        statement.buffer.write(')');
        statement.space();
    }
  }

  void addInsertStatement(InsertStatement insert) {
    _currentInsertStatement = insert;
    // For INSERT FROM SELECT statements, we move the select statement into a
    // CTE. This allows re-ordering columns from the select statement into the
    // right columns for the insert. The final SQL statement will look like
    // this:
    // WITH _source AS $select INSERT INTO $table (...) SELECT ... FROM _source
    if (insert.source case InsertFromSelect(:final select)) {
      statement.buffer.write('WITH _source AS (');
      select.compileWith(this);
      statement.buffer.write(')');
    }

    addInsertStatementMode(insert);
    statement.space();
    addFromResultSet(FromResultSet(insert.table),
        isWatching: false, write: UpdateKind.insert);
    statement.space();

    addInsertColumnNames(insert);
    (insert.source ?? InsertDefaultValues()).compileWith(this);

    if (insert.upsertClause case final upsert?) {
      if (insert.source is InsertFromSelect) {
        // Resolve parsing ambiguity (a `ON` from the conflict clause could also
        // be parsed as a join).
        statement.buffer.write(' WHERE TRUE ');
      } else {
        statement.space();
      }

      upsert.compileWith(this);
    }

    if (insert.returning case final returning?) {
      statement.space();
      returning.compileWith(this);
    }
  }

  void addReturningClause(ReturningClause returning) {
    // We currently only support the `RETURNING *` format without arbitrary
    // columns.
    statement.buffer.write('RETURNING *');
  }

  void addSelectStatement(BaseSelectStatement select) {
    final isRoot = statement.buffer.isEmpty;
    if (isRoot) {
      statement.isReadOnly = true;
    }

    statement.buffer.write('SELECT ');
    if (select.distinct) {
      statement.buffer.write('DISTINCT ');
    }
    statement.resultSetStructure = select.structure;
    statement.hasMultipleTables |= select.from.length > 1;

    var first = true;
    if (!_ignoreResultSet) {
      select.structure.expressions.forEach((expr, position) {
        if (!first) {
          statement.comma();
        }
        first = false;

        expr.compileWith(this);
        statement.buffer.write(' AS ');
        addReference(position.name);
      });
    } else {
      statement.buffer.write('1');
    }

    _ignoreResultSet = false;

    if (select.from case [final first, ...final rest]) {
      statement.buffer.write(' FROM ');
      first.compileWith(this);

      for (final entry in rest) {
        if (entry is! Join) {
          statement.buffer.write(', ');
        } else {
          statement.space();
        }

        entry.compileWith(this);
      }
    }

    if (select.whereClause case final where?) {
      statement.space();
      where.compileWith(this);
    }

    if (select.groupByClause case final groupBy?) {
      statement.space();
      groupBy.compileWith(this);
    }

    for (final compound in select.compounds) {
      compound.compileWith(this);
    }

    if (select.orderByClause case final orderBy?) {
      statement.space();
      orderBy.compileWith(this);
    }

    if (select.limitClause case final limit?) {
      statement.space();
      limit.compileWith(this);
    }

    if (isRoot) {
      statement.semicolon();
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
      throw ArgumentError(
          'Error compiling subquery expression $e, inner query must have exactly one column.');
    }

    statement.buffer.write('(');
    e.statement.compileWith(this);
    statement.buffer.write(')');
  }

  void addSubquery(Subquery e) {
    statement.buffer.write('(');
    e.select.compileWith(this);
    statement.buffer.write(') ');
    addReference(e.aliasOrName);
  }

  void addExistsExpression(ExistsExpression e) {
    final outerHasMultipleTables = statement.hasMultipleTables;
    final outerIgnoreResultSet = _ignoreResultSet;
    // Inside this subquery, we want to reference columns with their table
    // to avoid ambiguities when an outer table is referenced.
    statement.hasMultipleTables = true;

    writeExpression(e, () {
      if (e.not) {
        statement.buffer.write('NOT ');
      }
      statement.buffer.write('EXISTS ');

      statement.buffer.write('(');
      _expressionPrecedence = null; // No longer an expression context
      _ignoreResultSet = true;
      e.select.compileWith(this);
      statement.buffer.write(')');
    });

    statement.hasMultipleTables = outerHasMultipleTables;
    _ignoreResultSet = outerIgnoreResultSet;
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
      _expressionPrecedence = null; // We're inside of parentheses
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
        statement.buffer.write(' FILTER (WHERE ');
        filter.compileWith(this);
        statement.buffer.write(')');
      }
    });
  }

  void addLimit(Limit limit) {
    statement.buffer.write('LIMIT ${limit.amount}');

    if (limit.offset case final offset?) {
      statement.buffer.write(' OFFSET $offset');
    }
  }

  void addOrderBy(OrderBy orderBy) {
    if (orderBy.terms.isNotEmpty) {
      statement.buffer.write('ORDER BY ');
      addCommaSeparated(orderBy.terms);
    }
  }

  void addOrderingTerm(OrderingTerm term) {
    term.expression.compileWith(this);
    statement.space();
    statement.buffer.write(term.mode.lexeme);
    if (term.nulls case final nullsOrder?) {
      statement.space();
      statement.buffer.write(nullsOrder.lexeme);
    }
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

  void addCollateExpression(CollateExpression expr) {
    writeExpression(expr, () {
      expr.source.compileWith(this);
      statement.buffer.write(' COLLATE ');
      statement.buffer.write(expr.collation.name);
    });
  }

  void addUnaryExpression(UnaryExpression expr) {
    writeExpression(expr, () {
      if (expr.operator.isPrefix) {
        addUnaryOperator(expr.operator);
        if (expr.operator.needsSpace) statement.space();
        expr.operand.compileWith(this);
      } else {
        expr.operand.compileWith(this);
        if (expr.operator.needsSpace) statement.space();
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
      _expressionPrecedence = null;
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

  void addColumnDefaultConstraint(ColumnDefaultConstraint constraint) {
    statement.buffer.write('DEFAULT ');
    final isLiteral = constraint.defaultExpression is Literal;
    if (!isLiteral) statement.buffer.write('(');
    constraint.defaultExpression.compileWith(this);
    if (!isLiteral) statement.buffer.write(')');
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
      statement.buffer.write('DEFERRABLE INITIALLY DEFERRED');
    }
  }

  void addColumnCheckConstraint(ColumnCheckConstraint constraint) {
    statement.buffer.write('CHECK(');
    constraint.check.compileWith(this);
    statement.buffer.write(')');
  }

  void addCustom(CustomComponent component) {
    statement.watchedTables.addAll(component.watchedTables);
    statement.buffer.write(component.sqlFor(dialect.known));
  }

  void addCurrentDateOrTimeExpression(CurrentDateOrTimeExpression e) {
    writeExpression(e, () {
      statement.buffer
          .write(e.includeTime ? 'CURRENT_TIMESTAMP' : 'CURRENT_DATE');
    });
  }

  void addUpsertMultiple(UpsertMultiple multiple) {
    for (final (i, entry) in multiple.clauses.indexed) {
      if (i != 0) statement.space();
      entry.compileWith(this);
    }
  }

  void addDoNothing(DoNothing clause) {
    addOnConflictConstraint(target: clause.target);
    statement.buffer.write(' DO NOTHING');
  }

  void addDoUpdate(DoUpdate clause) {
    statement.hasMultipleTables |= clause.usesExcludedTable;
    final table = _currentInsertStatement!.table;

    addOnConflictConstraint(
        target: clause.target, where: clause.buildTargetCondition(table));
    statement.buffer.write(' DO UPDATE SET ');

    final updateSet = clause.createInsertable(table).toColumns(true);
    for (final (i, update) in updateSet.entries.indexed) {
      if (i != 0) statement.comma();

      addReference(update.key);
      statement.buffer.write(' = ');
      update.value.compileWith(this);
    }

    if (clause.buildWhereClause(table) case final where?) {
      statement.space();
      where.compileWith(this);
    }
  }

  void addOnConflictConstraint(
      {List<TableColumn>? target, WhereClause? where}) {
    statement.buffer.write('ON CONFLICT');

    if (target != null && target.isEmpty) {
      // An empty list indicates that no explicit target should be generated
      // by drift, the default rules by the database will apply instead.
      return;
    }

    statement.buffer.write('(');
    final conflictTarget =
        target ?? _currentInsertStatement!.table.primaryKey!.toList();

    if (conflictTarget.isEmpty) {
      throw ArgumentError(
          'Table has no primary key, so a conflict target is needed.');
    }

    var first = true;
    for (final target in conflictTarget) {
      if (!first) statement.comma();

      addReference(target.name);
      first = false;
    }

    statement.buffer.write(')');

    if (where != null) {
      statement.space();
      where.compileWith(this);
    }
  }

  void addInsertDefaultValues(InsertDefaultValues source) {
    statement.buffer.write('DEFAULT VALUES');
  }

  void addInsertFromValues(InsertFromValues source) {
    statement.buffer.write('VALUES (');
    addCommaSeparated(source.values.values);
    statement.buffer.write(')');
  }

  void addInsertFromSelect(InsertFromSelect source) {
    // We're moving the select statement to a CTE, see [addInsertStatement].
    statement.buffer.write('SELECT ');
    for (final (i, value)
        in source.columnNameToSelectColumnName.values.indexed) {
      if (i != 0) statement.comma();

      statement.buffer.write('_source.');
      addReference(value.name);
    }
  }

  void addGroupBy(GroupBy groupBy) {
    statement.buffer.write('GROUP BY ');
    addCommaSeparated(groupBy.groupBy);

    if (groupBy.having case final having?) {
      statement.buffer.write(' HAVING ');
      having.compileWith(this);
    }
  }

  void addCompoundOperator(CompoundOperator operator) {
    statement.buffer.write(operator.defaultLexeme);
  }

  void addCompoundSelect(CompoundSelect select) {
    statement.space();
    select.operator.compileWith(this);
    statement.space();
    select.statement.compileWith(this);
  }

  void addUnixTimestampToDateTime(UnixTimestampToDateTime e);

  void addDateExtractionOperator(DateExtractionOperator e);
}
