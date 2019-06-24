part of 'package:moor/moor_web.dart';

JsObject _alasql = context['alasql'] as JsObject;
JsFunction _jsonStringify = context['JSON']['stringify'] as JsFunction;

class AlaSqlDatabase extends QueryExecutor {
  JsObject _database;
  final bool logStatements;
  final String name;

  Completer<bool> _opening;

  AlaSqlDatabase(this.name, {this.logStatements = false}) {
    _registerFunctions();

    if (_alasql == null) {
      throw UnsupportedError('Could not access the alasql javascript library. '
          'The moor documentation contains instructions on how to setup moor '
          'the web, which might help you fix this.');
    }

    _database = JsObject(_alasql['Database'] as JsFunction);
  }

  @override
  TransactionExecutor beginTransaction() {
    throw StateError(
        'Transactions are not currently supported with the AlaSQL backend');
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
    // AlaSQL doesn't give us any information about the schema version, so we
    // first need to access the database without AlaSQL to find that out
    if (!IdbFactory.supported) {
      throw UnsupportedError("This browser doesn't support IndexedDb");
    }

    int version;
    var upgradeNeeded = false;

    final db = await window.indexedDB.open(
      name,
      version: databaseInfo.schemaVersion,
      onUpgradeNeeded: (event) {
        upgradeNeeded = true;
        version = event.oldVersion;
      },
    );
    db.close();

    // todo handle possible injection vulnerability of $name
    await _run('CREATE INDEXEDDB DATABASE IF NOT EXISTS `$name`;', const []);
    await _run('ATTACH INDEXEDDB DATABASE `$name`;', const []);
    await _run('USE `$name`;', const []);

    if (upgradeNeeded) {
      if (version == null || version < 1) {
        await databaseInfo.handleDatabaseCreation(executor: _runWithoutArgs);
      } else {
        await databaseInfo.handleDatabaseVersionChange(
            executor: _runWithoutArgs,
            from: version,
            to: databaseInfo.schemaVersion);
      }
    }
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    throw StateError(
        'Batched statements are not currently supported with AlaSQL');
  }

  Future<dynamic> _runWithoutArgs(String query) {
    return _run(query, const []);
  }

  Future<dynamic> _run(String query, List variables) {
    final completer = Completer<dynamic>();

    final args = [
      query,
      JsArray.from(variables),
      allowInterop((data, error) {
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete(data);
        }
      })
    ];

    _database.callMethod('exec', args);

    return completer.future;
  }

  @override
  Future<void> runCustom(String statement) {
    _runWithoutArgs(statement);
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
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List args) async {
    final result = await _run(statement, args) as JsArray;

    return result.map((row) {
      final jsRow = row as JsObject;
      // todo this is a desperate attempt at converting the JsObject to a Map.
      // Surely, there must be a better way to do this?
      final objJson = _jsonStringify.apply([jsRow]) as String;
      final dartMap = json.decode(objJson);

      return dartMap as Map<String, dynamic>;
    }).toList();
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return Future.value(_run(statement, args) as int);
  }
}
