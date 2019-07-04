part of 'package:moor/moor_web.dart';

/// Experimental moor backend for the web. To use this platform, you need to
/// include the latest version of `sql.js` in your html.
class WebDatabase extends QueryExecutor {
  final bool logStatements;
  final String name;

  Completer<bool> _openingCompleter;
  SqlJsDatabase _db;

  WebDatabase(this.name, {this.logStatements = false});

  @override
  TransactionExecutor beginTransaction() {
    throw StateError(
        'Transactions are not currently supported with the sql.js backend');
  }

  @override
  Future<bool> ensureOpen() async {
    // sync mechanism to make sure _openInternal is only called once
    if (_db != null) {
      return true;
    } else if (_openingCompleter != null) {
      return _openingCompleter.future;
    } else {
      _openingCompleter = Completer();
      await _openInternal();
      _openingCompleter.complete(true);
      return true;
    }
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

    final module = await initSqlJs();
    final restored = _restoreDb();
    _db = module.createDatabase(restored);

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
    final data = _db.export();
    final binStr = base64.encode(data);
    window.localStorage[_persistenceKey] = binStr;
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
    _db.runWithArgs(sql, variables);
  }

  Future<void> _runWithoutArgs(String query) {
    _db.run(query);
    return Future.value(null);
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

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    for (var stmt in statements) {
      final prepared = _db.prepare(stmt.sql);

      for (var args in stmt.variables) {
        prepared.executeWith(args);
      }
    }

    await _handlePotentialUpdate();
  }

  /// Saves the database if the last statement changed rows. As a side-effect,
  /// saving the database resets the `last_insert_id` counter in sqlite.
  Future<int> _handlePotentialUpdate() {
    final modified = _db.lastModifiedRows();
    if (modified > 0) {
      _storeDb();
    }
    return Future.value(modified);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    _runSimple(statement, args);
    final insertId = _db.lastInsertId();
    await _handlePotentialUpdate();
    return insertId;
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List args) async {
    _log(statement, args);
    // todo at least for stream queries we should cache prepared statements.
    final stmt = _db.prepare(statement)..executeWith(args);

    List<String> columnNames;
    final rows = <Map<String, dynamic>>[];

    while (stmt.step()) {
      columnNames ??= stmt.columnNames();
      final row = stmt.currentRow();

      rows.add({for (var i = 0; i < row.length; i++) columnNames[i]: row[i]});
    }

    stmt.free();
    return rows;
  }
}
