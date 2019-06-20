part of 'package:moor/moor_web.dart';

JsObject _alasql = context['alasql'] as JsObject;

class AlaSqlDatabase extends QueryExecutor {
  JsObject _database;
  final bool logStatements;
  final String name;

  Completer<bool> _opening;

  AlaSqlDatabase(this.name, {this.logStatements = false}) {
    if (_alasql == null) {
      throw UnsupportedError('Could not access the alasql javascript library. '
          'The moor documentation contains instructions on how to setup moor '
          'the web, which might help you fix this.');
    }

    _database = JsObject(_alasql['Database'] as JsFunction);
  }

  @override
  TransactionExecutor beginTransaction() {
    throw StateError('Transactions are not currently supported with AlaSQL');
  }

  @override
  Future<bool> ensureOpen() async {
    if (_opening == null) {
      _opening = Completer();
      await _openInternal();
      _opening.complete();
    } else {
      await _opening.future;
    }

    return true;
  }

  Future<void> _openInternal() async {
    // todo handle possible injection vulnerability of $name
    await _run('CREATE INDEXEDDB DATABASE IF NOT EXISTS `$name`;', const []);
    await _run('ATTACH INDEXEDDB DATABASE `$name`;', const []);
    await _run('USE `$name`;', const []);
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    throw StateError(
        'Batched statements are not currently supported with AlaSQL');
  }

  Future<dynamic> _run(String query, List variables) {
    JsObject promise;
    if (variables.isEmpty) {
      promise = _database.callMethod('promise', [query]) as JsObject;
    } else {
      promise = _database
          .callMethod('promise', [query, JsArray.from(variables)]) as JsObject;
    }

    return promiseToFuture(promise);
  }

  @override
  Future<void> runCustom(String statement) {
    _run(statement, const []);
    return Future.value();
  }

  @override
  Future<int> runDelete(String statement, List args) {
    return Future.value(_run(statement, args) as int);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    // todo (needs api change). We need to know the table and column name
    // to get the last insert id in AlaSQL. See https://github.com/agershun/alasql/wiki/AUTOINCREMENT
    _run(statement, args);

    return Future.value(42);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    // TODO: implement runSelect
    return null;
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return Future.value(_run(statement, args) as int);
  }
}
