import 'dart:async';

import 'package:collection/collection.dart';
import 'package:moor/backends.dart';
import 'package:moor/moor.dart' show GeneratedDatabase;
import 'package:moor/src/utils/hash.dart';

/// A query executor is responsible for executing statements on a database and
/// return their results in a raw form.
///
/// This is an internal api of moor, which can break often. If you want to
/// implement custom database backends, consider using the new `backends` API.
/// The [moor_flutter implementation](https://github.com/simolus3/moor/blob/develop/moor_flutter/lib/moor_flutter.dart)
/// might be useful as a reference. If you want to write your own database
/// engine to use with moor and run into issues, please consider creating an
/// issue.
abstract class QueryExecutor {
  /// The higher-level database class attached to this executor. This
  /// information can be used to read the [GeneratedDatabase.schemaVersion] when
  /// opening the database.
  GeneratedDatabase databaseInfo;

  /// The [SqlDialect] to use for this database engine.
  SqlDialect get dialect => SqlDialect.sqlite;

  /// Performs the async [fn] after this executor is ready, or directly if it's
  /// already ready.
  Future<T> doWhenOpened<T>(FutureOr<T> Function(QueryExecutor e) fn) {
    return ensureOpen().then((_) => fn(this));
  }

  /// Opens the executor, if it has not yet been opened.
  Future<bool> ensureOpen();

  /// Runs a select statement with the given variables and returns the raw
  /// results.
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args);

  /// Runs an insert statement with the given variables. Returns the row id or
  /// the auto_increment id of the inserted row.
  Future<int> runInsert(String statement, List<dynamic> args);

  /// Runs an update statement with the given variables and returns how many
  /// rows where affected.
  Future<int> runUpdate(String statement, List<dynamic> args);

  /// Runs an delete statement and returns how many rows where affected.
  Future<int> runDelete(String statement, List<dynamic> args);

  /// Runs a custom SQL statement without any variables. The result of that
  /// statement will be ignored.
  Future<void> runCustom(String statement, [List<dynamic> args]);

  /// Prepares the [statements] and then executes each one with all of the
  /// [BatchedStatement.variables].
  Future<void> runBatched(List<BatchedStatement> statements);

  /// Starts a [TransactionExecutor].
  TransactionExecutor beginTransaction();

  /// Closes this database connection and releases all resources associated with
  /// it. Implementations should also handle [close] calls in a state where the
  /// database isn't open.
  Future<void> close() async {
    // no-op per default for backwards compatibility
  }
}

/// A statement that should be executed in a batch. Used internally by moor.
class BatchedStatement {
  static const _nestedListEquality = ListEquality(ListEquality());

  /// The raw sql that needs to be executed
  final String sql;

  /// The variables to be used for the statement. Each entry holds a list of
  /// variables that should be bound to the [sql] statement.
  final List<List<dynamic>> variables;

  /// Constructs a batched statement from the [sql] and the set of [variables].
  BatchedStatement(this.sql, this.variables);

  @override
  int get hashCode {
    return $mrjf($mrjc(sql.hashCode, const ListEquality().hash(variables)));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is BatchedStatement &&
            other.sql == sql &&
            _nestedListEquality.equals(variables, other.variables));
  }

  @override
  String toString() {
    return 'BatchedStatement($sql, $variables)';
  }
}

/// A [QueryExecutor] that runs multiple queries atomically.
abstract class TransactionExecutor extends QueryExecutor {
  /// Completes the transaction. No further queries may be sent to to this
  /// [QueryExecutor] after this method was called.
  ///
  /// This may be called before [ensureOpen] was awaited, implementations must
  /// support this. That state implies that no query was sent, so it should be
  /// a no-op.
  Future<void> send();

  /// Cancels this transaction. No further queries may be sent ot this
  /// [QueryExecutor] after this method was called.
  ///
  /// This may be called before [ensureOpen] was awaited, implementations must
  /// support this. That state implies that no query was sent, so it should be
  /// a no-op.
  Future<void> rollback();
}
