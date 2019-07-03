part of 'package:moor/moor_web.dart';

const _initSqlJs = 'initSqlJs';

// ignore_for_file: cascade_invocations

/// Experimental moor backend for the web. To use this platform, you need to
/// include the latest version of `sql.js` in your html.
class WebDatabase extends QueryExecutor {
  final bool logStatements;
  final String name;

  Completer<bool> _opening;
  JsObject _database;

  // resolves to the SQL module. See the `initSqlJs` call in https://github.com/kripken/sql.js#example-html-file
  // This completer resolves to the `SQL` variable in that example.
  static Completer<JsObject> _initializedWasm;

  WebDatabase(this.name, {this.logStatements = false}) {
    if (context.hasProperty(_initSqlJs) == null) {
      throw UnsupportedError('Could not access the sql.js javascript library. '
          'The moor documentation contains instructions on how to setup moor '
          'the web, which might help you fix this.');
    }
    _loadWasmIfNeeded();
  }

  void _loadWasmIfNeeded() {
    if (_initializedWasm != null) return;

    _initializedWasm = Completer();
    // initSqlJs().then((sql) => _initialitedWasm.complete(sql));
    final promise = context.callMethod(_initSqlJs) as JsObject;
    promise.callMethod('then', [
      allowInterop((JsObject data) {
        _initializedWasm.complete(data);
      })
    ]);
  }

  @override
  TransactionExecutor beginTransaction() {
    throw StateError(
        'Transactions are not currently supported with the sql.js backend');
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
    // We don't get information about the database version from sql.js, so we
    // create another database just to manage versions.
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

    final sql = await _initializedWasm.future;
    final restored = _restoreDb();
    // var db = new SQL.Database()
    _database = JsObject(sql['Database'] as JsFunction,
        restored != null ? [restored] : const []);
    assert(() {
      // set the window.db variable to make debugging easier
      context['db'] = _database;
      return true;
    }());

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

  String get _persistenceKey => 'moor_db_str_$name';

  // todo base64 works, but is very slow. Figure out why bin2str is broken

  Uint8List _restoreDb() {
    final raw = window.localStorage[_persistenceKey];
    if (raw != null) {
      return base64.decode(raw);
    }
    return null;
  }

  void _storeDb() {
    final data = _database.callMethod('export') as Uint8List;
    final binStr = base64.encode(data);
    window.localStorage[_persistenceKey] = binStr;
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    throw StateError(
        'Batched statements are not currently supported with the web backend');
  }

  @tryInline
  void _log(String sql, List<dynamic> variables) {
    if (logStatements) {
      print('[moor_web]: Running $sql with bound args: $variables');
    }
  }

  /// Executes [sql] with the bound [variables], and ignores the result.
  void _runSimple(String sql, List<dynamic> variables) {
    _log(sql, variables);
    if (variables.isEmpty) {
      _database.callMethod('run', [sql]);
    } else {
      _database.callMethod('run', [sql, JsArray.from(variables)]);
    }
  }

  Future<void> _runWithoutArgs(String query) {
    _runSimple(query, const []);
    return Future.value(null);
  }

  /// Returns the amount of rows affected by the most recent INSERT, UPDATE or
  /// DELETE statement.
  int _getModifiedRows() {
    return _database.callMethod('getRowsModified') as int;
  }

  @override
  Future<void> runCustom(String statement) {
    return _runWithoutArgs(statement);
  }

  @override
  Future<int> runDelete(String statement, List args) {
    _runSimple(statement, args);
    return _handlePotentialUpdate();
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    _runSimple(statement, args);
    return _handlePotentialUpdate();
  }

  Future<int> _handlePotentialUpdate() {
    final modified = _getModifiedRows();
    if (modified > 0) {
      _storeDb();
    }
    return Future.value(modified);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    // todo get last insert id
    _runSimple(statement, args);
    _handlePotentialUpdate();
    return Future.value(42);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List args) async {
    _log(statement, args);
    // todo at least for stream queries we should cache prepared statements.
    final stmt = _database.callMethod('prepare', [statement]) as JsObject;
    stmt.callMethod('bind', [args]);

    List<String> columnNames;
    final rows = <Map<String, dynamic>>[];

    while (stmt.callMethod('step') as bool) {
      columnNames ??=
          (stmt.callMethod('getColumnNames') as JsArray).cast<String>();

      final row = stmt.callMethod('get') as JsArray;
      rows.add({for (var i = 0; i < row.length; i++) columnNames[i]: row[i]});
    }

    stmt.callMethod('free');
    return rows;
  }
}
