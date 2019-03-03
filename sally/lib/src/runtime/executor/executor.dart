import 'dart:async';

import 'package:sally/src/runtime/database.dart';

/// A query executor is responsible for executing statements on a database and
/// return their results in a raw form.
abstract class QueryExecutor {
  GeneratedDatabase databaseInfo;

  /// Performs the async [fn] after this executor is ready, or directly if it's
  /// already ready.
  Future<T> doWhenOpened<T>(FutureOr<T> fn(QueryExecutor e)) {
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
  Future<void> runCustom(String statement);
}
