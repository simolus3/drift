import 'package:meta/meta.dart';

import '../connection/connection.dart';
import '../connection/result_set.dart';
import '../connection/streams/update_rules.dart';
import '../query_builder/expressions/expression.dart';
import '../query_builder/expressions/variables.dart';
import '../query_builder/schema/table.dart';
import '../query_builder/statements/delete.dart';
import '../query_builder/statements/insert.dart';
import '../query_builder/statements/select.dart';
import '../query_builder/statements/statement.dart';
import '../query_builder/statements/query.dart';
import '../query_builder/statements/update.dart';
import 'connection_user.dart';
import 'data_class.dart';

/// Creates a [Batch] from [user]. Internal to not expose the constructor.
@internal
Batch createBatch(DatabaseConnectionUser user) {
  return Batch._(user);
}

@internal
Future<BatchResult> runBatch(Batch batch) async {
  return await batch._run();
}

/// Contains operations to run queries in a batched mode.
///
/// Inside a batch, a set of SQL statements is collected and then run at once.
/// Conceptually, batches are similar to a transaction (and they will use
/// transactions internally).
/// Additionally, batches are very efficient when the same SQL statement is
/// executed with different parameters. Outside of a batch, a new statement
/// would be parsed and prepared for each execution. With batches, statements
/// are only prepared once and then run with the parameters needed.
///
/// This makes batches particularly suitable for bulk updates.
final class Batch {
  /// A token object passed to [BatchedStatement] and [BatchResult] to ensure
  /// [BatchedStatement.resolveResult] is only called on compatible results.
  final Object _token = Object();

  final Map<String, int> _sqlToIndex = {};
  final List<String> _sql = [];
  final List<StatementInBatch> _statements = [];
  final Set<TableUpdate> _createdUpdates = {};

  /// The database on which the batch will run when completed.
  final DatabaseConnectionUser database;

  /// Creates a new pending batch on a [DatabaseConnectionUser].
  Batch._(this.database);

  /// Adds an [SqlStatement] to execute in this batch.
  ///
  /// All other high-level methods use this internally. It can also be used to
  /// add advanced statements to a batch when no shorthand method exists for
  /// those.
  BatchedStatement addStatement(SqlStatement stmt) {
    final built = database.dialect.compile(stmt);
    return _addCustomStatement(built);
  }

  BatchedStatement _addCustomStatement(StatementInfo info) {
    final stmtIndex = _sqlToIndex.putIfAbsent(info.sql, () {
      final newIndex = _sql.length;
      _sql.add(info.sql);
      return newIndex;
    });

    _createdUpdates.addAll(info.expectedWrites);

    final stmt = StatementInBatch(stmtIndex, info);
    final index = _statements.length;
    _statements.add(stmt);
    return BatchedStatement._(_token, index);
  }

  /// Inserts a row constructed from the fields in [row].
  ///
  ///
  /// [onConflict] can be used to create an upsert clause for engines that
  /// support it. For details and examples, see [InsertStatement.insert].
  ///
  /// See also:
  ///  - [InsertStatement.values], which would be used outside a [Batch].
  BatchedStatement
  insert<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    GeneratedTable<Row, RS> table,
    Insertable<Row> row, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    final stmt = InsertStatement<Row, RS>(database, table)..values(row);
    if (onConflict != null) {
      stmt.onConflict(onConflict);
    }

    return addStatement(stmt);
  }

  /// Inserts rows from the [select] statement.
  ///
  /// This method creates an `INSERT INTO SELECT` statement in SQL which will
  /// insert a row into this table for each row returned by the [select]
  /// statement.
  ///
  /// The [columns] map describes which column from the select statement should
  /// be written into which column of the table. The keys of the map are the
  /// target column, and values are expressions added to the select statement.
  ///
  /// See also:
  ///  - [InsertStatement.fromSelect], which would be used outside a
  ///  [Batch].
  BatchedStatement
  insertFromSelect<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    GeneratedTable<Row, RS> table,
    BaseSelectStatement select, {
    required Map<TableColumn, Expression> columns,
    UpsertClause<Row, RS>? onConflict,
  }) {
    final stmt = InsertStatement<Row, RS>(database, table)
      ..fromSelect(select, columns: columns);
    if (onConflict != null) {
      stmt.onConflict(onConflict);
    }

    return addStatement(stmt);
  }

  /// Inserts all [rows] into the [table].
  ///
  /// Using [insertAll] will not disable primary keys or any column constraint
  /// checks.
  ///
  /// [onConflict] can be used to create an upsert clause for engines that
  /// support it. For details and examples, see [InsertStatement.insert].
  void insertAll<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    GeneratedTable<Row, RS> table,
    Iterable<Insertable<Row>> rows, {
    UpsertClause<Row, RS>? onConflict,
  }) {
    for (final row in rows) {
      insert<Row, RS>(table, row, onConflict: onConflict);
    }
  }

  /// Equivalent of [InsertStatement.insertOnConflictUpdate] for multiple rows
  /// that will be inserted in this batch.
  void insertAllOnConflictUpdate<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table, Iterable<Insertable<Row>> rows) {
    for (final row in rows) {
      insert<Row, RS>(table, row, onConflict: DoUpdate((_) => row));
    }
  }

  /// Writes all present columns from the [row] into all rows in the [table]
  /// that match the [where] clause.
  ///
  /// For more details on how updates work in drift, check out
  /// [UpdateStatement.write] or the [documentation with examples](https://drift.simonbinder.eu/docs/dart-api/writes/#updates-and-deletes)
  BatchedStatement
  update<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    GeneratedTable<Row, RS> table,
    Insertable<Row> row, {
    Expression<bool> Function(RS table)? where,
  }) {
    final stmt = UpdateStatement(database, table)..setValues(row);
    if (where != null) stmt.where(where);

    return addStatement(stmt);
  }

  /// Replaces the [row] from the [table] with the updated values. The row in
  /// the table with the same primary key will be replaced.
  ///
  /// See also:
  ///  - [UpdateStatement.replace], which is what would be used outside of a
  ///    [Batch].
  BatchedStatement replace<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table, Insertable<Row> row) {
    return addStatement(UpdateStatement(database, table)..prepareReplace(row));
  }

  /// Helper that calls [replace] for all [rows].
  void replaceAll<Row extends Object, RS extends GeneratedTable<Row, RS>>(
    GeneratedTable<Row, RS> table,
    Iterable<Insertable<Row>> rows,
  ) {
    for (final row in rows) {
      replace(table, row);
    }
  }

  /// Deletes [row] from the [table] when this batch is executed.
  ///
  /// See also:
  /// - [DatabaseConnectionUser.delete]
  /// - [DeleteStatement.delete]
  BatchedStatement delete<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table, Insertable<Row> row) {
    final stmt = DeleteStatement(database, table)..whereSamePrimaryKey(row);
    return addStatement(stmt);
  }

  /// Deletes all rows from [table] matching the provided [filter].
  ///
  /// See also:
  ///  - [DatabaseConnectionUser.delete]
  BatchedStatement deleteWhere<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table, Expression<bool> Function(RS tbl) filter) {
    final stmt = DeleteStatement(database, table)..where(filter);
    return addStatement(stmt);
  }

  /// Deletes ALL rows from [table].
  ///
  /// See also:
  ///  - [DatabaseConnectionUser.delete]
  BatchedStatement deleteAll<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table) {
    final stmt = DeleteStatement(database, table);
    return addStatement(stmt);
  }

  /// Executes the custom [sql] statement with variables instantiated to [args].
  ///
  /// The statement will be added to this batch and executed when the batch
  /// completes. So, this method returns synchronously and it's not possible to
  /// inspect the return value of individual statements.
  ///
  /// See also:
  ///  - [DatabaseConnectionUser.customStatement], the equivalent method outside
  ///    of batches.
  BatchedStatement customStatement(
    String sql, {
    List<Variable> args = const [],
    Iterable<TableUpdate> updates = const {},
  }) {
    return _addCustomStatement(
      StatementInfo(
        sql,
        variables: [
          for (final variable in args) variable.resolveValue(database.dialect),
        ],
        expectedWrites: updates.toSet(),
      ),
    );
  }

  Future<BatchResult> _run() async {
    return await database.transaction(() async {
      final session = await database.currentSession();
      final results = await session.executeBatch(
        StatementBatch(sql: _sql, statements: _statements),
      );
      database.notifyUpdates(_createdUpdates);

      return BatchResult._(_token, results);
    });
  }
}

/// Results of running statements from a [Batch].
final class BatchResult {
  final Object _token;

  final List<QueryResult> _results;

  BatchResult._(this._token, this._results);
}

/// A statement that was created through a [Batch].
///
/// After later obtaining a [BatchResult] from running the batch, this instance
/// can be used to resolve the result of running a particular statement within
/// the batch.
final class BatchedStatement {
  final Object _token;

  /// Index into [Batch._statements].
  final int _index;

  BatchedStatement._(this._token, this._index);

  /// Looks up the raw [QueryResult] obtained from running the statement in the
  /// given [result].
  QueryResult resolveResult(BatchResult result) {
    if (!identical(result._token, _token)) {
      throw ArgumentError.value(
        result,
        'result',
        'That result is not from the batch used to run this statement',
      );
    }

    return result._results[_index];
  }
}
