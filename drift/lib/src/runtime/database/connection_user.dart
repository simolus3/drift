import 'dart:async';

import 'package:meta/meta.dart';

import '../../connections/connection.dart';
import '../../query_builder.dart';
import '../../query_builder/dialect.dart';
import '../exceptions.dart';
import 'db_base.dart';

const _zoneRootUserKey = #DatabaseConnectionUser;

/// The shared base class for drift databases and database accessors.
abstract base class DatabaseConnectionUser {
  /// The database class that this user is attached to.
  @visibleForOverriding
  GeneratedDatabase get attachedDatabase;

  /// The [DriftDialect] implementation for this opened database.
  DriftDialect get dialect => attachedDatabase.implementation.dialect;

  /// The current [DriftSession] that this database will use to run statements.
  Future<DriftSession> currentSession() {
    if (Zone.current[_zoneRootUserKey] case final scoped?) {
      return Future.value((scoped as _ScopedDatabaseSession)._session);
    } else {
      return attachedDatabase.rootConnection();
    }
  }

  /// Executes [action] in a transaction, which means that all its queries and
  /// updates will be called atomically.
  ///
  /// Returns the value of [action].
  /// When [action] throws an exception, the transaction will be reset and no
  /// changes will be applied to the databases. The exception will be rethrown
  /// by [transaction].
  ///
  /// The behavior of stream queries in transactions depends on where the stream
  /// was created:
  ///
  /// - streams created outside of a [transaction] block: The stream will update
  ///   with the tables modified in the transaction after it completes
  ///   successfully. If the transaction fails, the stream will not update.
  /// - streams created inside a [transaction] block: The stream will update for
  ///   each write in the transaction. When the transaction completes,
  ///   successful or not, streams created in it will close. Writes happening
  ///   outside of this transaction will not affect the stream.
  ///
  /// Starting from drift version 2.0, nested transactions are supported on most
  /// database implementations (including `NativeDatabase`, `WebDatabase`,
  /// `WasmDatabase`, `SqfliteQueryExecutor`, databases relayed through
  /// isolates or web workers).
  /// When calling [transaction] inside a [transaction] block on supported
  /// database implementations, a new transaction will be started.
  /// For backwards-compatibility, the current transaction will be re-used if
  /// a nested transaction is started with a database implementation not
  /// supporting nested transactions. The [requireNew] parameter can be set to
  /// instead turn this case into a runtime error.
  ///
  /// Nested transactions are conceptionally similar to regular, top-level
  /// transactions in the sense that their writes are not seen by users outside
  /// of the transaction until it is commited. However, their behavior around
  /// completions is different:
  ///
  /// - When a nested transaction completes, nothing is being persisted right
  ///   away. The parent transaction can now see changes from the child
  ///   transaction and continues to run. When the outermost transaction
  ///   completes, its changes (including changes from child transactions) are
  ///   written to the database.
  /// - When a nested transaction is aborted (which happens due to exceptions),
  ///   only changes in that inner transaction are reverted. The outer
  ///   transaction can continue to run if it catched the exception thrown by
  ///   the inner transaction when it aborted.
  ///
  /// See also:
  ///  - the docs on [transactions](https://drift.simonbinder.eu/docs/transactions/)
  Future<T> transaction<T>(Future<T> Function() action,
      {TransactionOptions? options}) async {
    final resolved = await currentSession();
    final transaction = await (resolved as DriftTransactionParent)
        .begin(options ?? TransactionOptions());

    return _runConnectionZoned(_ScopedDatabaseSession(transaction), () async {
      var success = false;

      try {
        final result = await action();
        success = true;
        return result;
      } catch (e, s) {
        await transaction.rollbackAfterException(e, s);

        // pass the exception on to the one who called transaction()
        rethrow;
      } finally {
        if (success) {
          try {
            await transaction.commit();
          } catch (e, s) {
            // Couldn't commit -> roll back then.
            await transaction.rollbackAfterException(e, s);
            rethrow;
          }
        }

        // TODO: await transaction.disposeChildStreams();
      }
    });
  }

  /// Obtains an exclusive lock on the current database context, runs [action]
  /// in it and then releases the lock.
  ///
  /// This obtains a local lock on the underlying [executor] without starting a
  /// transaction or coordinating with other processes on the same database.
  /// It is possible to start a [transaction] within an [exclusively] block.
  /// When [exclusively] is called on a database connected to a remote isolate
  /// or a shared web worker, other isolates and tabs will be blocked on the
  /// database until the returned future completes.
  ///
  /// With sqlite3, [exclusively] is useful to set certain pragmas like
  /// `foreign_keys` which can't be done in a transaction for a limited scope.
  /// For instance, some migrations may look like this:
  ///
  /// ```dart
  /// await exclusively(() async {
  ///   await customStatement('pragma foreign_keys = OFF;');
  ///   await transaction(() async {
  ///     // complex updates or migrations temporarily breaking foreign
  ///     // references...
  ///   });
  ///   await customStatement('pragma foreign_keys = OFF;');
  /// });
  /// ```
  ///
  /// If the [exclusively] block had been omitted from the previous snippet,
  /// it would have been possible for other concurrent database calls to occur
  /// between the transaction and the `pragma` statements.
  ///
  /// Outside of blocks requiring exclusive access to set pragmas not supported
  /// in transactions, consider using [transaction] instead of [exclusively].
  /// Transactions also take exclusive control over the database, but they also
  /// are atomic (either all statements in a transaction complete or none at
  /// all), whereas an error in an [exclusively] block does not roll back
  /// earlier statements.
  Future<T> exclusively<T>(Future<T> Function() action) async {
    final resolved = await currentSession();
    final exclusive =
        await (resolved as DriftSessionWithInternalLocks).exclusive();

    return _runConnectionZoned(
      _ScopedDatabaseSession(exclusive),
      () async {
        try {
          return await action();
        } finally {
          exclusive.close();
        }
      },
    );
  }

  /// Runs [calculation] in a forked [Zone] that has its [currentSession] set
  /// to the [session].
  @protected
  Future<T> _runConnectionZoned<T>(
      _ScopedDatabaseSession session, Future<T> Function() calculation) {
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: session});
  }

  /// Creates a copy of the table with an alias so that it can be used in the
  /// same query more than once.
  ///
  /// Example which uses the same table (here: points) more than once to
  /// differentiate between the start and end point of a route:
  /// ```
  /// var source = alias(points, 'source');
  /// var destination = alias(points, 'dest');
  ///
  /// select(routes).join([
  ///   innerJoin(source, routes.startPoint.equalsExp(source.id)),
  ///   innerJoin(destination, routes.startPoint.equalsExp(destination.id)),
  /// ]);
  /// ```
  RS alias<Row extends Object, RS extends ResultSet<Row, RS>>(
      ResultSet<Row, RS> table, String alias) {
    return table.withAlias(alias).asSelfType();
  }

  /// Starts a query on the given table.
  ///
  /// In drift, queries are commonly used as a builder by chaining calls on
  /// them. For instance, to load the 10 oldest users
  /// with an 'S' in their name, you could use:
  /// ```dart
  /// Future<List<User>> oldestUsers() {
  ///   return select(users)
  ///     .where((u) => u.name.like('%S%'))
  ///     .orderBy([(u) => OrderingTerm(
  ///         expression: u.id,
  ///         mode: OrderingMode.asc
  ///      )])
  ///     .limit(10)
  ///     .get();
  /// }
  /// ```
  ///
  /// The [distinct] parameter (defaults to false) can be used to remove
  /// duplicate rows from the result set.
  ///
  /// For more information on queries, see the
  /// [documentation](https://drift.simonbinder.eu/docs/getting-started/writing_queries/).
  SingleTableSelectStatement<Row, RS>
      select<Row extends Object, RS extends ResultSet<Row, RS>>(
          ResultSet<Row, RS> table,
          {bool distinct = false}) {
    return SingleTableSelectStatement<Row, RS>(this, table, distinct: distinct);
  }
}

final class _ScopedDatabaseSession {
  final DriftSession _session;

  _ScopedDatabaseSession(this._session);
}

extension on DriftTransactionSession {
  Future<void> rollbackAfterException(
      Object exception, StackTrace trace) async {
    try {
      await rollback();
    } catch (rollBackException) {
      throw CouldNotRollBackException(exception, trace, rollBackException);
    }
  }
}
