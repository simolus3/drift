import 'dart:async';

import '../query_builder/compiler.dart';
import '../query_builder/dialect.dart';
import '../query_builder/types.dart';
import '../runtime/streams/delayed_stream_queries.dart';
import '../runtime/streams/store.dart';
import '../runtime/streams/store_impl.dart';
import '../runtime/streams/update_rules.dart';
import 'result_set.dart';

final class DriftDatabaseImplementation {
  final DriftDialect dialect;
  final Future<DriftSession> Function() _openConnection;

  final StreamQueryStore? streamQueries;

  DriftDatabaseImplementation({
    required this.dialect,
    required Future<DriftSession> Function() openConnection,
    this.streamQueries,
  }) : _openConnection = openConnection;

  static DriftDatabaseImplementation delayed(
      Future<DriftDatabaseImplementation> Function() open,
      {required DriftDialect dialect}) {
    final session = Completer<DriftSession>();
    final streamQueries = Completer<StreamQueryStore>();

    Future<void> request() {
      if (!session.isCompleted) {
        session.complete(Future(() async {
          final connection = await open();
          final (conn, queries) = await connection.open();

          streamQueries.complete(queries);
          return conn;
        }));
      }

      return session.future;
    }

    return DriftDatabaseImplementation(
      dialect: dialect,
      openConnection: () async {
        await request();
        return await session.future;
      },
      streamQueries: DelayedStreamQueryStore(
        streamQueries.future,
        request,
      ),
    );
  }

  Future<(DriftSession, StreamQueryStore)> open() async {
    final session = await _openConnection();
    return (session, streamQueries ?? LocalStreamQueryStore());
  }
}

abstract interface class DriftTransactionParent {
  Future<DriftSession> begin(TransactionOptions options);
}

abstract interface class DriftSessionWithInternalLocks {
  Future<DriftSession> exclusive();
}

abstract interface class DriftTransactionSession {
  Future<void> commit();
  Future<void> rollback();
}

abstract interface class DriftSession {
  Future<QueryResult> execute(StatementInfo statement);
  Future<List<QueryResult>> executeBatch(StatementBatch batch);

  /// An arbitrary and user-defined tag that may be attached to sessions.
  ///
  /// For [DriftSession]s implemented as isolate clients, this tag stores the
  /// `SendPort` used to connect to the isolate.
  /// This allows to obtain another [DriftSession] given an existing one by
  /// extracting its [tag].
  abstract final Object? tag;

  /// If this session has schema management method, a [DriftRootSession]
  /// instance exposing them.
  DriftRootSession? get root;

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

  bool get isClosed;
  Future<void> get closed;
  Future<void> close();
}

abstract interface class DriftRootSession {
  Future<int> get schemaVersion;
  Future<void> writeSchemaVersion(int version);
}

final class StatementBatch {
  final List<String> sql;
  final List<StatementInBatch> statements;

  StatementBatch({required this.sql, required this.statements});
}

final class StatementInBatch {
  final int sqlIndex;
  final StatementInfo info;

  StatementInBatch(this.sqlIndex, this.info);
}

final class StatementInfo {
  final CompiledStatement? generated;

  final String sql;
  final bool needsResultSet;
  final List<MappedValue> variables;
  final Set<TableUpdate> expectedWrites;
  final bool isReadOnly;

  StatementInfo(CompiledStatement this.generated)
      : sql = generated.buffer.toString(),
        needsResultSet = generated.resultSetStructure != null,
        variables = generated.variables
            .map((e) => MappedValue.map(e.$1, generated.dialect, e.$2))
            .toList(),
        isReadOnly = generated.isReadOnly,
        expectedWrites = generated.possibleUpdates;

  StatementInfo.fromText(
    this.sql, {
    this.variables = const [],
    this.needsResultSet = false,
    this.isReadOnly = false,
    this.expectedWrites = const {},
  }) : generated = null;

  @override
  String toString() {
    return '$sql, $variables';
  }
}

/// A value used when binding SQL parameters to statements.
extension type const MappedValue._((SqlType, Object?) _value) {
  /// Creates a [MappedValue] from the given [type] and [rawValue] components.
  factory MappedValue.raw(SqlType type, Object? rawValue) {
    return MappedValue._((type, rawValue));
  }

  /// Applies [SqlType.sqlParameter] on the given [type] and [dartValue] using
  /// the provided [dialect].
  static MappedValue map<T extends Object>(
      SqlType<T> type, DriftDialect dialect, T? dartValue) {
    return MappedValue.raw(type, type.sqlParameterOrNull(dialect, dartValue));
  }

  /// The type of the variable.
  ///
  /// This value is preserved because some implementations need to know the
  /// original when binding values. This is particularly true for Postgres,
  /// where `null` values need to have an associated type. Being given the
  /// [rawValue] alone would not be enough.
  SqlType get type => _value.$1;

  /// The value obtained by calling [SqlType.sqlParameter] on the original value
  /// and the associated [type].
  Object? get rawValue => _value.$2;
}

extension ApplyMapping on Iterable<TypedNullableValue> {
  /// Maps all value in this iterable to sql using the given [dialect].
  List<MappedValue> toSql(DriftDialect dialect) {
    return [
      for (final (type, dartValue) in this)
        MappedValue.map(type, dialect, dartValue)
    ];
  }
}

/// An interface describing options to use when beginning a transaction.
///
/// This is not currently used, but introduced as a parameter on
/// [DriftTransactionParent.begin] to preserve forwards-compatibility if options
/// are introduced in the future.
final class TransactionOptions {
  // We might eventually use this to implement read-only transactions, which can
  // be used to optimize connection pools.
}
