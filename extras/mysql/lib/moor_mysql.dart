/// Experimental support to run moor on a mysql backend.
library moor_mysql;

import 'package:moor/backends.dart';
import 'package:moor/moor.dart';
import 'package:sqljocky5/connection/connection.dart';
import 'package:sqljocky5/sqljocky.dart';

export 'package:sqljocky5/sqljocky.dart' show ConnectionSettings;

class MySqlBackend extends DelegatedDatabase {
  MySqlBackend(ConnectionSettings settings)
      : super(_MySqlDelegate(settings), logStatements: true);
}

mixin _MySqlExecutor on QueryDelegate {
  Querier get _querier;

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    for (var stmt in statements) {
      await _querier.preparedMulti(stmt.sql, stmt.variables);
    }
  }

  @override
  Future<void> runCustom(String statement, List args) async {
    await _querier.prepared(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    final result = await _querier.prepared(statement, args);
    return result.insertId;
  }

  @override
  Future<QueryResult> runSelect(String statement, List args) async {
    final result = await _querier.prepared(statement, args);

    final columns = [for (var field in result.fields) field.name];
    final rows = result.toList();

    return QueryResult(columns, rows);
  }

  @override
  Future<int> runUpdate(String statement, List args) async {
    final result = await _querier.prepared(statement, args);

    return result.affectedRows;
  }
}

class _MySqlDelegate extends DatabaseDelegate with _MySqlExecutor {
  final ConnectionSettings _settings;

  MySqlConnection _connection;

  _MySqlDelegate(this._settings);

  @override
  Future<bool> get isOpen async => _connection != null;

  @override
  Querier get _querier => _connection;

  @override
  final DbVersionDelegate versionDelegate = const NoVersionDelegate();

  @override
  TransactionDelegate get transactionDelegate => _TransactionOpener(this);

  @override
  Future<void> open([GeneratedDatabase db]) async {
    _connection = await MySqlConnection.connect(_settings);
  }

  @override
  Future<void> close() async {
    await _connection.close();
  }
}

class _TransactionOpener extends SupportedTransactionDelegate {
  final _MySqlDelegate _delegate;

  _TransactionOpener(this._delegate);

  @override
  void startTransaction(Future Function(QueryDelegate) run) {
    _delegate._connection.transaction((transaction) async {
      final executor = _TransactionExecutor(transaction);
      await run(executor);
    });
  }
}

class _TransactionExecutor extends QueryDelegate with _MySqlExecutor {
  @override
  final Querier _querier;

  _TransactionExecutor(this._querier);
}
