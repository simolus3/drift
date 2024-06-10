import 'dart:async' show FutureOr;

import 'package:drift/drift.dart';
import 'package:drift/src/runtime/executor/helpers/results.dart';

String _defaultSavepoint(int depth) => 'SAVEPOINT s$depth';

String _defaultRelease(int depth) => 'RELEASE s$depth';

String _defaultRollbackToSavepoint(int depth) => 'ROLLBACK TO s$depth';

/// An interface that supports sending database queries. Used as a backend for
/// drift.
///
/// Database implementations should support the following types both for
/// variables and result sets:
/// - [int]
/// - [double]
/// - [String]
/// - [Uint8List]
abstract class DatabaseDelegate extends QueryDelegate {
  /// Whether the database managed by this delegate is in a transaction at the
  /// moment. This field is only set when the [transactionDelegate] is a
  /// [NoTransactionDelegate], because in that case transactions are run on
  /// this delegate.
  bool isInTransaction = false;

  /// Returns an appropriate class to resolve the current schema version in
  /// this database.
  ///
  /// Common implementations will be:
  /// - [NoVersionDelegate] for databases without a schema version (such as an
  /// MySql server we connect to)
  /// - [OnOpenVersionDelegate] for databases whose schema version can only be
  /// set while opening it (such as sqflite)
  /// - [DynamicVersionDelegate] for databases where drift can set the schema
  /// version at any time (used for the web and VM implementation)
  DbVersionDelegate get versionDelegate;

  /// The way this database engine starts transactions.
  TransactionDelegate get transactionDelegate;

  /// A future that completes with `true` when this database is open and with
  /// `false` when its not. The future may never complete with an error or with
  /// null. It should return relatively quickly, as drift queries it before each
  /// statement it sends to the database.
  FutureOr<bool> get isOpen;

  /// Opens the database. Drift will only call this when [isOpen] has returned
  /// false before. Further, drift will not attempt to open a database multiple
  /// times, so you don't have to worry about a connection being created
  /// multiple times.
  ///
  /// The [QueryExecutorUser] is the user-defined database annotated with
  /// [DriftDatabase]. It might be useful to read the
  /// [QueryExecutorUser.schemaVersion] if that information is required while
  /// opening the database.
  Future<void> open(QueryExecutorUser db);

  /// Closes this database. When the future completes, all resources used
  /// by this database should have been disposed.
  Future<void> close() async {
    // default no-op implementation
  }

  /// Callback from drift after the database has been fully opened and all
  /// migrations ran.
  void notifyDatabaseOpened(OpeningDetails details) {
    // default no-op
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
  Future<QueryResult> runSelect(String statement, List<Object?> args);

  /// Prepares and executes the [statement] with the variables bound to [args].
  /// The statement will either be an `UPDATE` or `DELETE` statement.
  ///
  /// If the statement completes successfully, the amount of changed rows should
  /// be returned, or `0` if no rows where updated. Should throw if the
  /// statement can't be executed.
  Future<int> runUpdate(String statement, List<Object?> args);

  /// Prepares and executes the [statement] with the variables bound to [args].
  /// The statement will be an `INSERT` statement.
  ///
  /// If the statement completes successfully, the insert id of the row can be
  /// returned. If that information is not available, `null` can be returned.
  /// The method should throw if the statement can't be executed.
  Future<int> runInsert(String statement, List<Object?> args);

  /// Runs a custom [statement] with the given [args]. Ignores all results, but
  /// throws when the statement can't be executed.
  Future<void> runCustom(String statement, List<Object?> args);

  /// Runs multiple [statements] without having to prepare the same statement
  /// multiple times.
  ///
  /// See also:
  ///  - [QueryExecutor.runBatched].
  Future<void> runBatched(BatchedStatements statements) async {
    // default, inefficient implementation
    for (final application in statements.arguments) {
      final sql = statements.statements[application.statementIndex];

      await runCustom(sql, application.arguments);
    }
  }
}

/// An interface to start and manage transactions.
sealed class TransactionDelegate {
  /// Const constructor on superclass
  const TransactionDelegate();
}

/// A [TransactionDelegate] for database APIs which don't already support
/// creating transactions. Drift will send a `BEGIN TRANSACTION` statement at
/// the beginning, then block the database, and finally send a `COMMIT`
/// statement at the end.
final class NoTransactionDelegate extends TransactionDelegate {
  /// The statement that starts a transaction on this database engine.
  final String start;

  /// The statement that commits a transaction on this database engine.
  final String commit;

  /// The statement that will perform a rollback of a transaction on this
  /// database engine.
  final String rollback;

  /// The statement that will create a savepoint for a given depth of a transaction
  /// on this database engine.
  final String Function(int depth) savepoint;

  /// The statement that will release a savepoint for a given depth of a transaction
  /// on this database engine.
  final String Function(int depth) release;

  /// The statement that will perform a rollback to a savepoint for a given depth
  /// of a transaction on this database engine.
  final String Function(int depth) rollbackToSavepoint;

  /// Construct a transaction delegate indicating that native transactions
  /// aren't supported and need to be emulated by issuing statements and
  /// locking the database.
  const NoTransactionDelegate({
    this.start = 'BEGIN TRANSACTION',
    this.commit = 'COMMIT TRANSACTION',
    this.rollback = 'ROLLBACK TRANSACTION',
    this.savepoint = _defaultSavepoint,
    this.release = _defaultRelease,
    this.rollbackToSavepoint = _defaultRollbackToSavepoint,
  });
}

/// A [TransactionDelegate] for database APIs which do support creating and
/// managing transactions themselves.
abstract class SupportedTransactionDelegate extends TransactionDelegate {
  /// Constant constructor on superclass
  const SupportedTransactionDelegate();

  /// Whether [startTransaction] will ensure further requests to the parent
  /// database are delayed until the callback completes.
  ///
  /// When this returns `false`, drift will manage a lock internally to ensure
  /// statements are only sent to the transaction while its active.
  ///
  /// For implementations that support being in a transaction and outside of a
  /// transaction concurrently, this should return `true`.
  bool get managesLockInternally => true;

  /// Start a transaction, which we assume implements [QueryDelegate], and call
  /// [run] with the transaction.
  ///
  /// If [run] completes with an error, rollback. Otherwise, commit.
  ///
  /// The returned future should complete once the transaction has been commited
  /// or was rolled back.
  FutureOr<void> startTransaction(Future Function(QueryDelegate) run);
}

/// A [TransactionDelegate] for database APIs that have it's own transaction
/// function
@Deprecated('Use SupportedTransactionDelegate instead')
abstract class WrappedTransactionDelegate extends SupportedTransactionDelegate {
  /// Constant constructor on superclass
  const WrappedTransactionDelegate();

  @override
  bool get managesLockInternally => false;

  @override
  FutureOr<void> startTransaction(Future Function(QueryDelegate p1) run) async {
    await runInTransaction(run);
  }

  /// Start a transaction, which we assume implements [QueryDelegate], and call
  /// [run] with the transaction.
  ///
  /// If [run] completes with an error, rollback. Otherwise, commit.
  Future runInTransaction(Future Function(QueryDelegate) run);
}

/// An interface that supports setting the database version.
sealed class DbVersionDelegate {
  /// Constant constructor on superclass
  const DbVersionDelegate();
}

/// A database that doesn't support setting schema versions.
final class NoVersionDelegate extends DbVersionDelegate {
  /// Delegate indicating that the underlying database does not support schema
  /// versions.
  const NoVersionDelegate();
}

/// A database that only support setting the schema version while being opened.
final class OnOpenVersionDelegate extends DbVersionDelegate {
  /// Function that returns with the current schema version.
  final Future<int> Function() loadSchemaVersion;

  /// See [OnOpenVersionDelegate].
  const OnOpenVersionDelegate(this.loadSchemaVersion);
}

/// A database that supports setting the schema version at any time.
abstract class DynamicVersionDelegate extends DbVersionDelegate {
  /// See [DynamicVersionDelegate]
  const DynamicVersionDelegate();

  /// Load the current schema version stored in this database.
  Future<int> get schemaVersion;

  /// Writes the schema [version] to the database.
  Future<void> setSchemaVersion(int version);
}
