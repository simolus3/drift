import 'dart:async';

import '../query_builder/dialect.dart';
import '../query_builder/types.dart';
import 'result_set.dart';
import 'streams/delayed_stream_queries.dart';
import 'streams/in_memory_store.dart';
import 'streams/store.dart';
import 'streams/update_rules.dart';

/// The underlying database connection implementation used for drift databases.
final class DriftDatabaseImplementation {
  /// The outermost [DriftSession] representing the opened connection or
  /// connection pool.
  final DriftSession session;

  /// The [StreamQueryStore] implementation used to implement auto-updating
  /// query streams.
  final StreamQueryStore streamQueries;

  /// @nodoc
  DriftDatabaseImplementation(this.session, this.streamQueries);
}

/// A pending connection that can be opened into a
/// [DriftDatabaseImplementation].
///
/// [DriftConnection] instances don't hold any resources before [open] is
/// called.
final class DriftConnection {
  /// The dialect to use when generating SQL statements.
  ///
  /// This should always correspond to the [DriftDatabaseImplementation] opened
  /// by this session. SQLite connections would use a SQLite dialect.
  final DriftDialect dialect;
  final Future<DriftDatabaseImplementation> Function() _openConnection;

  /// @nodoc
  DriftConnection({
    required this.dialect,
    required Future<DriftSession> Function() openConnection,
    bool closeStreamsSynchronously = false,
    StreamQueryStore? streamQueries,
  }) : _openConnection = _wrapOpenSession(
         openConnection,
         streamQueries,
         closeStreamsSynchronously,
       );

  /// A drift connection resolving to the [implementation] when [open]ed.
  DriftConnection.withImplementation({
    required this.dialect,
    required Future<DriftDatabaseImplementation> Function() implementation,
  }) : _openConnection = implementation;

  /// A drift connection referring to another [DriftConnection] lazily when
  /// opening.
  static DriftConnection delayed(
    Future<DriftConnection> Function() open, {
    required DriftDialect dialect,
  }) {
    final session = Completer<DriftSession>();
    final streamQueries = Completer<StreamQueryStore>();

    Future<void> request() {
      if (!session.isCompleted) {
        session.complete(
          Future(() async {
            final connection = await open();
            final implementation = await connection.open();

            streamQueries.complete(implementation.streamQueries);
            return implementation.session;
          }),
        );
      }

      return session.future;
    }

    return DriftConnection(
      dialect: dialect,
      openConnection: () async {
        await request();
        return await session.future;
      },
      streamQueries: DelayedStreamQueryStore(streamQueries.future, request),
    );
  }

  /// Opens the connection.
  ///
  /// The returned implementation should eventually be closed to avoid leaking
  /// resources.
  Future<DriftDatabaseImplementation> open() async {
    return await _openConnection();
  }

  /// Returns a [DriftConnection] that has the underlying [DriftSession]
  /// replaced by the [change] function.
  DriftConnection changeSession(
    FutureOr<DriftSession> Function(DriftSession) change,
  ) {
    return DriftConnection.withImplementation(
      dialect: dialect,
      implementation: () async {
        final implementation = await open();
        return DriftDatabaseImplementation(
          await change(implementation.session),
          implementation.streamQueries,
        );
      },
    );
  }

  static Future<DriftDatabaseImplementation> Function() _wrapOpenSession(
    Future<DriftSession> Function() session,
    StreamQueryStore? store,
    bool closeStreamsSynchronously,
  ) {
    return () async {
      return DriftDatabaseImplementation(
        await session(),
        store ??
            InMemoryStreamQueryStore(
              closeStreamsSynchronously: closeStreamsSynchronously,
            ),
      );
    };
  }
}

/// For sessions that support starting transactions, exposes an [begin] method
/// for starting transaction.
abstract interface class DriftTransactionParent {
  /// Starts a child [DriftSession] running statements in a transaction.
  ///
  /// The [DriftSession.transaction] of the returned session must be non-null,
  /// which allows using the [DriftTransactionSession] to commit or rollback the
  /// transaction.
  Future<DriftSession> begin(TransactionOptions options);
}

/// For sessions that can provide exclusive access to the database, exposes an
/// [exclusive] method.
abstract interface class DriftSessionWithInternalLocks {
  /// Obtains an exclusive lock on the database, and then returns a
  /// [DriftSession] instance which is the only session allowed to run
  /// statements on the parent session.
  ///
  /// Other operations are blocked until the returned session is
  /// [DriftSession.close]d.
  Future<DriftSession> exclusive();
}

/// A handle to control transaction, expanding [DriftSession.close] to suppport
/// explicitly committing or rolling transactions back.
abstract interface class DriftTransactionSession {
  /// Commits this transaction scope.
  ///
  /// This is a final operation, meaning that this session should be
  /// [DriftSession.closed] afterwards.
  Future<void> commit();

  /// Rolls back changes made in this transaction scope.
  ///
  /// This is a final operation, meaning that this session should be
  /// [DriftSession.closed] afterwards.
  Future<void> rollback();
}

/// A session used to run statements against a database.
///
/// In drift, database connections (or even database pools) can implement
/// [DriftSession] to execute queries. Additionally, [DriftSession] instances
/// are also used to represent transactions starte on a connection. While such
/// an inner session is active, the outer one is typically blocked (unless the
/// database supports multiple concurrent transactions, which might be the case
/// for e.g. a PostgreSQL pool).
///
/// All [DriftSession] implementations provide [execute] and [executeBatch]
/// methods. Optional functionality is exposed through nullable getters:
///
///  - Top-level connections typically implement [schemaVersion] to support
///    drift's schema management.
///  - If the driver supports opening transactions, [transactionParent] should
///    return an implementation for that. Drivers don't need to support this
///    though, drift can also run `BEGIN` and `COMMIT` statements manually.
///  - In a transaction, [transaction] should return an instance allowing
///    transactions to be committed or rolled back.
abstract interface class DriftSession {
  /// Runs the given SQL [StatementInfo], returning results.
  Future<QueryResult> execute(StatementInfo statement);

  /// Prepares all statements in the batch, then runs them at once.
  ///
  /// This can be more efficient than calling [execute] multiple times since
  /// the costs of parsing SQL statements is amortized across the batch.
  Future<List<QueryResult>> executeBatch(StatementBatch batch);

  /// An arbitrary and user-defined tag that may be attached to sessions.
  ///
  /// For [DriftSession]s implemented as isolate clients, this tag stores the
  /// `SendPort` used to connect to the isolate.
  /// This allows to obtain another [DriftSession] given an existing one by
  /// extracting its [tag].
  abstract final Object? tag;

  /// If this session has schema management method, return a
  /// [PersistentSchemaVersion] instance for it.
  PersistentSchemaVersion? get persistentSchemaVersion;

  /// If this session represents a a transaction, returns a
  /// [DriftTransactionSession] that can be used to commit or rollback the
  /// transaction.
  ///
  /// This getter should always return the same value, existing session
  /// instances can't start being a transaction after being open.
  DriftTransactionSession? get transaction;

  /// If this session can open transactions, a [DriftTransactionParent] through
  /// which transactions can be started.
  DriftTransactionParent? get transactionParent;

  /// If this session can be locked, a [DriftSessionWithInternalLocks] instance
  /// through which an exclusive lock on the session can be obtained.
  DriftSessionWithInternalLocks? get locks;

  /// Whether this session has been closed, meaning that no further operations
  /// can run on it.
  bool get isClosed;

  /// A future that completes as [isClosed] becomes `true`.
  Future<void> get closed;

  /// Closes this drift session, releasing associated resources.
  Future<void> close();
}

/// A schema version that can be persisted in a database.
///
/// This allows different implementations, like a `PRAGMA application_version`
/// in SQLite or a dedicated migration table in other systems.
abstract interface class PersistentSchemaVersion {
  /// Loads the current schema version from the database.
  Future<int> get schemaVersion;

  /// Writes the given `version` into the database.
  Future<void> writeSchemaVersion(int version);
}

/// A batch of statements to prepare and run at once.
final class StatementBatch {
  /// All SQL statements to prepare and run.
  final List<String> sql;

  /// An instantiation providing parameters for [sql] statements that are part
  /// of this batch.
  final List<StatementInBatch> statements;

  /// @nodoc
  StatementBatch({required this.sql, required this.statements});
}

/// An instantiated statement in a [StatementBatch].
final class StatementInBatch {
  /// The index in [StatementBatch.sql] of the statement to run.
  final int sqlIndex;

  /// Parameters for the statement to run.
  final StatementInfo info;

  /// @nodoc
  const StatementInBatch(this.sqlIndex, this.info);
}

/// Information about a SQL statement generated by drift's query builder.
final class StatementInfo {
  /// The generated SQL statement text for this statement.
  final String sql;

  /// Whether result rows should be fetched for this statement.
  ///
  /// Note that this is not the same as [isReadOnly], since this is also true
  /// for writes with a `RETURNING` clause.
  final bool needsResultSet;

  /// For placeholders or parameters in [sql], their values.
  final List<MappedValue> variables;

  /// For reading queries, all tables referenced in the `FROM` clause.
  ///
  /// This allows re-running this statement.
  final List<String> watchedTables;

  /// Expected [TableUpdate]s related to this statement.
  ///
  /// This indicates that drift expects that, if the statement completes
  /// successfully, it could have written to any of these updates.
  final Set<TableUpdate> expectedWrites;

  /// Whether this statement is known to be read-only.
  ///
  /// When using connection pools, read-only statements might be distributed to
  /// dedicated read-only connections for performance.
  final bool isReadOnly;

  /// @nodoc
  StatementInfo(
    this.sql, {
    this.watchedTables = const [],
    this.variables = const [],
    this.needsResultSet = false,
    this.isReadOnly = false,
    this.expectedWrites = const {},
  });

  @override
  String toString() {
    return '$sql, $variables';
  }
}

/// A value used when binding SQL parameters to statements.
extension type const MappedValue._((PhysicalSqlType, Object?) _value) {
  /// Creates a [MappedValue] from the given [type] and [rawValue] components.
  factory MappedValue.raw(PhysicalSqlType type, Object? rawValue) {
    return MappedValue._((type, rawValue));
  }

  /// Applies [PhysicalSqlType.sqlParameter] on the given [type] and
  /// [dartValue].
  static MappedValue map<T extends Object>(
    PhysicalSqlType<T> type,
    T? dartValue,
  ) {
    return MappedValue.raw(type, switch (dartValue) {
      null => null,
      var value => type.sqlParameter(value),
    });
  }

  /// The type of the variable.
  ///
  /// This value is preserved because some implementations need to know the
  /// original when binding values. This is particularly true for Postgres,
  /// where `null` values need to have an associated type. Being given the
  /// [rawValue] alone would not be enough.
  PhysicalSqlType get type => _value.$1;

  /// The value obtained by calling [SqlType.sqlParameter] on the original value
  /// and the associated [type].
  Object? get rawValue => _value.$2;
}

/// An interface describing options to use when beginning a transaction.
///
/// This is not currently used, but introduced as a parameter on
/// [DriftTransactionParent.begin] to preserve forwards-compatibility if options
/// are introduced in the future.
final class TransactionOptions {
  // We might eventually use this to implement read-only transactions, which can
  // be used to optimize connection pools.

  /// Whether foreign keys should only be checked at the end of the transaction
  /// instead of at each statement.
  final bool? deferForeignKeys;

  /// @nodoc
  const TransactionOptions({this.deferForeignKeys});
}
