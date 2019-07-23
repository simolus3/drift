import 'dart:typed_data' show Uint8List;
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/helpers/results.dart';

/// An interface that supports sending database queries. Used as a backend for
/// moor.
///
/// Database implementations should support the following types both for
/// variables and result sets:
/// - [int]
/// - [double]
/// - [String]
/// - [Uint8List]
abstract class DatabaseDelegate implements QueryDelegate {
  /// Returns an appropriate class to resolve the current schema version in
  /// this database.
  ///
  /// Common implementations will be:
  /// - [NoVersionDelegate] for databases without a schema version (such as an
  /// MySql server we connect to)
  /// - [OnOpenVersionDelegate] for databases whose schema version can only be
  /// set while opening it (such as sqflite)
  /// - [DynamicVersionDelegate] for databases where moor can set the schema
  /// version at any time (used for the web and VM implementation)
  DbVersionDelegate get versionDelegate;

  /// The way this database engine starts transactions.
  TransactionDelegate get transactionDelegate;

  /// A future that completes with `true` when this database is open and with
  /// `false` when its not. The future may never complete with an error or with
  /// null. It should return relatively quickly, as moor queries it before each
  /// statement it sends to the database.
  Future<bool> get isOpen;

  /// Opens the database. Moor will only call this when [isOpen] has returned
  /// false before. Further, moor will not attempt to open a database multiple
  /// times, so you don't have to worry about a connection being created
  /// multiple times.
  ///
  /// The [GeneratedDatabase] is the user-defined database annotated with
  /// [UseMoor]. It might be useful to read the [GeneratedDatabase.schemaVersion]
  /// if that information is required while opening the database.
  Future<void> open([GeneratedDatabase db]);

  /// Closes this database. When the future completes, all resources used
  /// by this database should have been disposed.
  Future<void> close() async {
    // default no-op implementation
  }
}

/// An interface which can execute sql statements.
abstract class QueryDelegate {
  /// Prepares and executes the [statement], binding the variables to [args].
  /// Its safe to assume that the [statement] is a select statement, the
  /// [QueryResult] that it returns should be returned from here.
  ///
  /// If the statement can't be executed, an exception should be thrown. See
  /// the class documentation of [DatabaseDelegate] on what types are supported.
  Future<QueryResult> runSelect(String statement, List<dynamic> args);

  /// Prepares and executes the [statement] with the variables bound to [args].
  /// The statement will either be an `UPDATE` or `DELETE` statement.
  ///
  /// If the statement completes successfully, the amount of changed rows should
  /// be returned, or `0` if no rows where updated. Should throw if the
  /// statement can't be executed.
  Future<int> runUpdate(String statement, List<dynamic> args);

  /// Prepares and executes the [statement] with the variables bound to [args].
  /// The statement will be an `INSERT` statement.
  ///
  /// If the statement completes successfully, the insert id of the row can be
  /// returned. If that information is not available, `null` can be returned.
  /// The method should throw if the statement can't be executed.
  Future<int> runInsert(String statement, List<dynamic> args);

  /// Runs a custom [statement] with the given [args]. Ignores all results, but
  /// throws when the statement can't be executed.
  Future<void> runCustom(String statement, List<dynamic> args);

  /// Runs each of the [statements] with all set of variables in each
  /// [BatchedStatement.variables]. For database APIs that support preparing
  /// statements, this allows us to only prepare a statement once for each
  /// [BatchedStatement], which can be executed multiple times.
  Future<void> runBatched(List<BatchedStatement> statements) async {
    // default, inefficient implementation
    for (var stmt in statements) {
      for (var boundVars in stmt.variables) {
        await runCustom(stmt.sql, boundVars);
      }
    }
  }
}

/// An interface to start and manage transactions.
///
/// Clients may not extend, implement or mix-in this class directly.
abstract class TransactionDelegate {
  const TransactionDelegate();
}

/// A [TransactionDelegate] for database APIs which don't already support
/// creating transactions. Moor will send a `BEGIN TRANSACTION` statement at the
/// beginning, then block the database, and finally send a `COMMIT` statement
/// at the end.
class NoTransactionDelegate extends TransactionDelegate {
  /// The statement that starts a transaction on this database engine.
  final String start;

  /// The statement that commits a transaction on this database engine.
  final String commit;

  /// The statement that will perform a rollback of a transaction on this
  /// database engine.
  final String rollback;

  const NoTransactionDelegate({
    this.start = 'BEGIN TRANSACTION',
    this.commit = 'COMMIT TRANSACTION',
    this.rollback = 'ROLLBACK TRANSACTION',
  });
}

/// A [TransactionDelegate] for database APIs which do support creating and
/// managing transactions themselves.
abstract class SupportedTransactionDelegate extends TransactionDelegate {
  const SupportedTransactionDelegate();

  /// Start a transaction, which we assume implements [QueryEngine], and call
  /// [run] with the transaction.
  ///
  /// If [run] completes with an error, rollback. Otherwise, commit.
  void startTransaction(Future Function(QueryDelegate) run);
}

/// An interface that supports setting the database version.
///
/// Clients may not extend, implement or mix-in this class directly.
abstract class DbVersionDelegate {
  const DbVersionDelegate();
}

/// A database that doesn't support setting schema versions.
class NoVersionDelegate extends DbVersionDelegate {
  const NoVersionDelegate();
}

/// A database that only support setting the schema version while being opened.
class OnOpenVersionDelegate extends DbVersionDelegate {
  /// Function that returns with the current schema version.
  final Future<int> Function() loadSchemaVersion;

  const OnOpenVersionDelegate(this.loadSchemaVersion);
}

/// A database that supports setting the schema version at any time.
abstract class DynamicVersionDelegate extends DbVersionDelegate {
  const DynamicVersionDelegate();

  /// Load the current schema version stored in this database.
  Future<int> get schemaVersion;

  /// Writes the schema [version] to the database.
  Future<void> setSchemaVersion(int version);
}
