// ignore_for_file: public_member_api_docs

import 'package:collection/collection.dart';

import '../connection/connection.dart';
import '../connection/streams/update_rules.dart';
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
import 'expressions/window.dart';
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

/// A mutable buffer of SQL text, parameters and associated state.
///
/// This is used by [StatementCompiler] implementations to generate SQL from
/// Dart.
final class StatementBuffer {
  /// The [DriftDialect] for which this statement has been generated.
  final DriftDialect dialect;

  /// The [StringBuffer] building SQL text.
  final StringBuffer buffer = StringBuffer();

  /// Instantiations of parameters (typically from [Variable] instances) that
  /// have been added to the statement.
  final List<MappedValue> variables = [];
  final Map<Variable, int> _variableIndexes = {};

  /// For read-only queries, a set of tables directly referenced in the query.
  ///
  /// This is used to build query streams: Whenever any of these tables changes,
  /// we re-run the query.
  final Set<ResultSet> watchedTables = {};

  /// A set of tables that might get updated when running the statement.
  ///
  /// This set being empty does not imply [isReadOnly], it's possible we just
  /// don't know the exact tables being updated.
  final Set<TableUpdate> possibleUpdates = {};

  /// Whether the generated statement does not alter any database state.
  bool isReadOnly = false;

  /// The last index of a SQL variable that has already been used in this
  /// statement, or `0` initially.
  int variableOffset = 0;

  /// Whether this statement operates on multiple tables.
  ///
  /// When enabled, references to columns are generated with a table reference
  /// on them.
  bool hasMultipleTables = false;

  /// Whether variables are supposed in the generated statement.
  ///
  /// This is false in e.g. `CREATE TABLE` statements.
  bool supportsVariables = true;

  /// For statements that return columns, the [ResultSetStructure] describing
  /// expected columns.
  ResultSetStructure? resultSetStructure;

  /// Creates an empty statement buffer.
  StatementBuffer(this.dialect);

  /// Writes a space into this statement's buffer.
  void space() => buffer.write(' ');

  /// Writes a comma into this statement's buffer.
  void comma() => buffer.write(',');

  /// Writes a semicolon into this statement's buffer.
  void semicolon() => buffer.write(';');

  /// Returns a [StatementInfo] reflecting the current state of this compiled
  /// statement buffer.
  StatementInfo toStatementInfo() {
    return StatementInfo(
      buffer.toString(),
      variables: variables.toList(),
      needsResultSet: resultSetStructure != null,
      isReadOnly: isReadOnly,
      expectedWrites: possibleUpdates,
    );
  }
}

/// Base class for anything that can be compiled to SQL.
abstract interface class SqlComponent {
  /// Compiles this component with the given [StatementCompiler] by invoking the
  /// relevant `add` method on it.
  void compileWith(StatementCompiler compiler);
}

/// A common mixin for components with dialect-specific variants (or options
/// that only exist in some dialects).
///
/// See [dialectSpecificOptions] for more details on how this is used
/// internally.
abstract mixin class DialectSpecificComponent implements SqlComponent {
  /// A map of dialect-specific options.
  ///
  /// Typically, each key in the map is a static symbol constant defined in
  /// classes mixing in [DialectSpecificComponent].
  ///
  /// Dialect-specific imports then use extension methods to design a high-level
  /// API for each dialects.
  ///
  /// As an example of this, consider insert statements which have an `INSERT OR
  /// IGNORE /* OR ROLLBACK, OR ABORT, ... */` syntax in SQLite but not in
  /// PostgreSQL. By representing that option in [dialectSpecificOptions], we
  /// don't have to add a special `SqliteInsertStatement` subclass. Compiling
  /// those insert statements with a PostgreSQL compiler would simply ignore
  /// that option.
  ///
  /// This allows the [compileWith] implementation of this component to
  final Map<Symbol, Object?> dialectSpecificOptions = {};
}

/// A custom component, used to embed a fixed SQL string into drift-generated
/// statements.
final class CustomComponent implements SqlComponent {
  /// The SQL string to use for dialects not contained in [dialectSpecifcSql].
  final String fallbackSql;

  /// Dialect-specific overrides for the SQL text to generate.
  final Map<KnownSqlDialect, String> dialectSpecifcSql;

  /// Additional tables that this SQL construct is watching.
  ///
  /// When this component is used in a stream query, the stream will update
  /// when any table in [watchedTables] changes.
  /// Usually, custom components don't introduce new tables to watch. This field
  /// is mainly used for view and subqueries used as expressions.
  final Iterable<ResultSet> watchedTables;

  /// Creates a custom component instance from the SQL text.
  const CustomComponent(
    this.fallbackSql, {
    this.dialectSpecifcSql = const {},
    this.watchedTables = const [],
  });

  /// The SQL text to generate for the specific [KnownSqlDialect].
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

/// A compiler that iteratively builds SQL text by recursively visiting a tree
/// of [SqlComponent]s.
///
/// Each compiler instance creates a single [StatementBuffer] containing the
/// SQL text, prepared statement parameters and information about involved
/// tables.
abstract base class StatementCompiler {
  /// The pending [StatementBuffer] used by this compiler instance.
  late final StatementBuffer statement = StatementBuffer(dialect);
  Precedence? _expressionPrecedence;

  bool _ignoreResultSet = false;
  InsertStatement? _currentInsertStatement;
  GeneratedView? _generatingCreateView;

  /// The dialect to use when compiling dialect-specific structures.
  DriftDialect get dialect;

  void addPositionalVariable(int index);

  void addTableColumnDefinition(TableColumn column) {
    addReference(column.name);
    statement.space();
    statement.buffer.write(column.type.typeName(dialect));

    final hasCustomConstraint = column.constraints.any(
      (e) => e is CustomColumnConstraint,
    );
    if (!hasCustomConstraint) {
      statement.space();

      statement.buffer.write(column.isNullable ? 'NULL' : 'NOT NULL');
    }

    for (final constraint in column.constraints) {
      if (constraint case CustomColumnConstraint(:final onlyOnDialect?)) {
        if (onlyOnDialect != dialect.known) {
          continue;
        }
      }

      statement.space();

      constraint.compileWith(this);
    }

    addDialectSpecificDefaultColumnConstraints(column);
  }

  void addDialectSpecificDefaultColumnConstraints(TableColumn column) {}

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

  void addFrameType(FrameType f) {
    statement.buffer.write(f.type);
  }

  void addFrameExclude(FrameExclude f) {
    statement.buffer.write(f.exclude);
  }

  void addFrameBoundaryElement(num exp) {
    if (exp == 0) {
      statement.buffer.write('CURRENT ROW');
    } else if (exp < 0) {
      Literal(exp.abs()).compileWith(this);
      statement.buffer.write(' PRECEDING');
    } else {
      Literal(exp.abs()).compileWith(this);
      statement.buffer.write(' FOLLOWING');
    }
  }

  void addFrameBoundary(FrameBoundary f) {
    addFrameType(f.frameType);
    statement.buffer.write(' BETWEEN ');
    if (f.start case final start?) {
      addFrameBoundaryElement(start);
    } else {
      statement.buffer.write('UNBOUNDED PRECEDING');
    }
    statement.buffer.write(' AND ');
    if (f.end case final end?) {
      addFrameBoundaryElement(end);
    } else {
      statement.buffer.write('UNBOUNDED FOLLOWING');
    }
    if (f.exclude case final exclude?) {
      statement.buffer.write(' EXCLUDE ');
      addFrameExclude(exclude);
    }
  }

  void addFromResultSet(
    FromResultSet resultSet, {
    bool isWatching = true,
    UpdateKind? write,
  }) {
    final resolved = resultSet.resultSet;
    if (resolved case final SqlComponent component) {
      component.compileWith(this);
    } else {
      if (isWatching) {
        statement.watchedTables.add(resultSet.resultSet);
      }
      if (write != null && resolved is GeneratedTable) {
        statement.isReadOnly = false;
        statement.possibleUpdates.add(
          TableUpdate.onTable(resolved, kind: write),
        );
      }

      addReference(resultSet.resultSet.entityName);
    }

    if (resultSet.resultSet.alias case final alias?) {
      statement.buffer.write(' AS ');
      addReference(alias);
    }
  }

  void addCreateTableStatement(CreateTableStatement stmt) {
    statement.supportsVariables = false;
    final table = stmt.entity;

    if (table case final VirtualTableInfo virtual) {
      statement.buffer.write('CREATE VIRTUAL TABLE ');
      if (stmt.ifNotExists) {
        statement.buffer.write('IF NOT EXISTS ');
      }
      addReference(table.entityName);
      statement.buffer.write(' USING ${virtual.moduleAndArgs}');
      return;
    }

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
      for (final constraint in table.constraints) {
        statement.comma();
        constraint.compileWith(this);
      }
    }

    for (final constraint in table.customConstraints) {
      statement
        ..comma()
        ..buffer.write(constraint);
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
      _generatingCreateView = create.entity;
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
    addFromResultSet(
      FromResultSet(delete.resultSet),
      isWatching: false,
      write: UpdateKind.delete,
    );

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
    addFromResultSet(
      FromResultSet(update.resultSet),
      isWatching: false,
      write: UpdateKind.update,
    );
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
    addFromResultSet(
      FromResultSet(insert.table),
      isWatching: false,
      write: UpdateKind.insert,
    );
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
      statement.resultSetStructure = select.structure;
    }

    statement.buffer.write('SELECT ');
    if (select.distinct) {
      statement.buffer.write('DISTINCT ');
    }

    statement.hasMultipleTables |= select.from.length > 1;

    var first = true;
    if (!_ignoreResultSet) {
      select.structure.expressions.forEach((expr, position) {
        if (!first) {
          statement.comma();
        }
        first = false;

        expr.compileWith(this);

        if (position.resultAlias case final alias?) {
          statement.buffer.write(' AS ');
          addReference(alias);
        }
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

  void addTypeName(PhysicalSqlType type) {
    statement.buffer.write(type.typeName);
  }

  void addTuple(ExpressionTuple tuple) {
    statement.buffer.write('(');
    addCommaSeparated(tuple.values);
    statement.buffer.write(')');
  }

  void addSubqueryExpression(SubqueryExpression e) {
    if (e.statement.structure.expressions.length != 1) {
      throw ArgumentError(
        'Error compiling subquery expression $e, inner query must have exactly one column.',
      );
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
    if (column.owningResultSet == _generatingCreateView) {
      (column as ViewColumn).expression.compileWith(this);
      return;
    }

    if (statement.hasMultipleTables) {
      final resultSet = column.owningResultSet;
      addReference(resultSet.aliasOrName);
      statement.buffer.write('.');
    }

    addReference(column.name);
  }

  void addWindowFunctionExpression(WindowFunctionExpression expr) {
    writeExpression(expr, () {
      expr.function.compileWith(this);
      statement.buffer.write(' OVER (');
      if (expr.partitionBy case final partitionBy?
          when partitionBy.isNotEmpty) {
        statement.buffer.write('PARTITION BY ');
        addCommaSeparated(partitionBy);
        statement.space();
      }
      expr.orderBy.compileWith(this);
      statement.space();
      addFrameBoundary(expr.boundary);
      statement.buffer.write(')');
    });
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

  void addLikeExpression(LikeExpression expr) {
    writeExpression(expr, () {
      expr.left.compileWith(this);
      statement.buffer.write(' LIKE ');
      expr.right.compileWith(this);

      if (expr.escape case final escape?) {
        statement.buffer.write(' ESCAPE ');
        escape.compileWith(this);
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
      statement.buffer.write(type.sqlLiteral(value));
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
    statement.buffer.write(
      stmt.depth == 0 ? 'BEGIN;' : 'SAVEPOINT s${stmt.depth};',
    );
  }

  /// Write a [CommitStatement] statement.
  void addCommit(CommitStatement stmt) {
    statement.buffer.write(
      stmt.depth == 0 ? 'COMMIT;' : 'RELEASE s${stmt.depth};',
    );
  }

  /// Write a [RollbackStatement] statement.
  void addRollback(RollbackStatement stmt) {
    statement.buffer.write('ROLLBACK');
    if (stmt.depth > 0) {
      statement.buffer.write(' TO s${stmt.depth}');
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
      'REFERENCES ${constraint.otherTableName} (${constraint.otherColumnName})',
    );
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
      statement.buffer.write(
        e.includeTime ? 'CURRENT_TIMESTAMP' : 'CURRENT_DATE',
      );
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
      target: clause.target,
      where: clause.buildTargetCondition(table),
    );
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

  void addOnConflictConstraint({
    List<TableColumn>? target,
    WhereClause? where,
  }) {
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
        'Table has no primary key, so a conflict target is needed.',
      );
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

  void addTablePrimaryKeyConstraint(TablePrimaryKeyConstraint e) {
    statement.buffer.write('PRIMARY KEY (');
    for (var i = 0; i < e.columns.length; i++) {
      if (i != 0) statement.comma();

      final column = e.columns[i];
      addReference(column.name);
    }
    statement.buffer.write(')');
  }

  void addTableUniqueKeyConstraint(TableUniqueKeyConstraint e) {
    statement.buffer.write('UNIQUE (');
    for (var i = 0; i < e.columns.length; i++) {
      if (i != 0) statement.comma();

      final column = e.columns[i];
      addReference(column.name);
    }
    statement.buffer.write(')');
  }

  void addUnixTimestampToDateTime(UnixTimestampToDateTime e);

  void addDateExtractionOperator(DateExtractionOperator e);
}
