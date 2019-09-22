import 'dart:async';

import 'package:moor_ffi/database.dart';

/// A opened sqlite database.
abstract class BaseDatabase {
  /// Closes this database connection and releases the resources it uses. If
  /// an error occurs while closing the database, an exception will be thrown.
  /// The allocated memory will be freed either way.
  FutureOr<void> close();

  /// Executes the [sql] statement and ignores the result. Will throw if an
  /// error occurs while executing.
  FutureOr<void> execute(String sql);

  /// Prepares the [sql] statement.
  FutureOr<BasePreparedStatement> prepare(String sql);

  /// Get the application defined version of this database.
  FutureOr<int> userVersion();

  /// Update the application defined version of this database.
  FutureOr<void> setUserVersion(int version);

  /// Returns the amount of rows affected by the last INSERT, UPDATE or DELETE
  /// statement.
  FutureOr<int> getUpdatedRows();

  /// Returns the row-id of the last inserted row.
  FutureOr<int> getLastInsertId();
}

/// A prepared statement that can be executed multiple times.
abstract class BasePreparedStatement {
  /// Executes this prepared statement as a select statement. The returned rows
  /// will be returned.
  FutureOr<Result> select([List<dynamic> args]);

  /// Executes this prepared statement.
  FutureOr<void> execute([List<dynamic> params]);

  /// Closes this prepared statement and releases its resources.
  FutureOr<void> close();
}
