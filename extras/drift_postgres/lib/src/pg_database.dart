import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/backends.dart';
import 'package:postgres/postgres.dart';

/// A drift database implementation that talks to a postgres database.
class PgDatabase extends DelegatedDatabase {
  PgDatabase({
    required Endpoint endpoint,
    ConnectionSettings? settings,
    bool logStatements = false,
    bool enableMigrations = true,
  }) : super(
          _PgDelegate(
            () => Connection.open(endpoint, settings: settings),
            true,
            enableMigrations,
          ),
          isSequential: true,
          logStatements: logStatements,
        );

  /// Creates a drift database implementation from a postgres database
  /// [connection].
  PgDatabase.opened(
    Session connection, {
    bool logStatements = false,
    bool enableMigrations = true,
  }) : super(_PgDelegate(() => connection, false, enableMigrations),
            isSequential: true, logStatements: logStatements);

  @override
  SqlDialect get dialect => SqlDialect.postgres;
}

class _PgDelegate extends DatabaseDelegate {
  _PgDelegate(
    this._open,
    this.closeUnderlyingWhenClosed,
    this.enableMigrations,
  );

  final bool closeUnderlyingWhenClosed;
  final bool enableMigrations;
  final FutureOr<Session> Function() _open;

  Session? _openedSession;

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen =>
      Future.value(_openedSession != null && _openedSession!.isOpen);

  @override
  Future<void> open(QueryExecutorUser user) async {
    final session = await _open();

    if (enableMigrations) {
      final pgVersionDelegate = _PgVersionDelegate(session);

      await pgVersionDelegate.init();
      versionDelegate = pgVersionDelegate;
    } else {
      versionDelegate = NoVersionDelegate();
    }

    _openedSession = session;
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final session = _openedSession!;
    final prepared =
        List<Statement?>.filled(statements.statements.length, null);

    try {
      for (final instantation in statements.arguments) {
        final pgArgs = _BoundArguments.ofDartArgs(instantation.arguments);

        // Lazily prepare statements when we run into them. The reason is that
        // we need to know the types for variables.
        final stmtIndex = instantation.statementIndex;
        var stmt = prepared[stmtIndex];
        if (stmt == null) {
          final sql = statements.statements[stmtIndex];
          stmt = prepared[stmtIndex] =
              await session.prepare(Sql(sql, types: pgArgs.types));
        }

        await stmt.run(pgArgs.parameters);
      }
    } finally {
      for (final stmt in prepared) {
        await stmt?.dispose();
      }
    }
  }

  Future<int> _runWithArgs(String statement, List<Object?> args) async {
    final session = _openedSession!;

    final pgArgs = _BoundArguments.ofDartArgs(args);
    final result = await session.execute(
      Sql(statement, types: pgArgs.types),
      parameters: pgArgs.parameters,
    );
    return result.affectedRows;
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final session = _openedSession!;
    final pgArgs = _BoundArguments.ofDartArgs(args);
    final result = await session.execute(Sql(statement, types: pgArgs.types),
        parameters: pgArgs.parameters);
    return result.firstOrNull?[0] as int? ?? 0;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    return _runWithArgs(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final session = _openedSession!;
    final pgArgs = _BoundArguments.ofDartArgs(args);
    final result = await session.execute(Sql(statement, types: pgArgs.types),
        parameters: pgArgs.parameters);

    return QueryResult([
      for (final pgColumn in result.schema.columns) pgColumn.columnName ?? '',
    ], result);
  }

  @override
  Future<void> close() async {
    if (closeUnderlyingWhenClosed) {
      if (_openedSession case final Connection c) {
        await c.close();
      }
    }
  }
}

class _BoundArguments {
  final List<Type> types;
  final List<TypedValue> parameters;

  _BoundArguments(this.parameters)
      : types = parameters.map((p) => p.type).toList(growable: false);

  factory _BoundArguments.ofDartArgs(List<Object?> args) {
    final parameters = List<TypedValue>.generate(
      args.length,
      (i) {
        final value = args[i];
        return switch (value) {
          TypedValue() => value,
          null ||
          int() ||
          String() ||
          bool() ||
          double() =>
            TypedValue(Type.unspecified, value),
          BigInt() => TypedValue(Type.bigInteger, value.checkRange.toInt()),
          List<int>() => TypedValue(Type.byteArray, value),
          _ => throw ArgumentError.value(value, 'value', 'Unsupported type'),
        };
      },
      growable: false,
    );

    return _BoundArguments(parameters);
  }
}

class _PgVersionDelegate extends DynamicVersionDelegate {
  final Session database;

  _PgVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion async {
    final result = await database.execute(Sql('SELECT version FROM __schema'));
    return result[0][0] as int;
  }

  Future init() async {
    await database.execute(Sql('CREATE TABLE IF NOT EXISTS __schema ('
        'version integer NOT NULL DEFAULT 0)'));

    final count = await database.execute(Sql('SELECT COUNT(*) FROM __schema'));
    if (count[0][0] as int == 0) {
      await database.execute(Sql('INSERT INTO __schema (version) VALUES (0)'));
    }
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await database.execute(
      Sql(r'UPDATE __schema SET version = $1', types: [Type.integer]),
      parameters: [
        TypedValue(Type.integer, version),
      ],
    );
  }
}

extension _BigIntRangeCheck on BigInt {
  static final _bigIntMinValue64 = BigInt.parse('-9223372036854775808');
  static final _bigIntMaxValue64 = BigInt.parse('9223372036854775807');

  BigInt get checkRange {
    if (this < _bigIntMinValue64 || this > _bigIntMaxValue64) {
      throw Exception('BigInt value exceeds the range of 64 bits');
    }
    return this;
  }
}