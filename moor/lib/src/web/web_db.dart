part of 'package:moor/moor_web.dart';

/// Experimental moor backend for the web. To use this platform, you need to
/// include the latest version of `sql.js` in your html.
class WebDatabase extends DelegatedDatabase {
  WebDatabase(String name, {bool logStatements = false})
      : super(_WebDelegate(name),
            logStatements: logStatements, isSequential: true);
}

class _WebDelegate extends DatabaseDelegate {
  final String name;
  SqlJsDatabase _db;

  String get _persistenceKey => 'moor_db_str_$name';

  bool _inTransaction = false;

  _WebDelegate(this.name);

  @override
  set isInTransaction(bool value) {
    _inTransaction = value;

    if (!_inTransaction) {
      // transaction completed, save the database!
      _storeDb();
    }
  }

  @override
  bool get isInTransaction => _inTransaction;

  @override
  final TransactionDelegate transactionDelegate = const NoTransactionDelegate();

  @override
  DbVersionDelegate get versionDelegate => _WebVersionDelegate(name);

  @override
  bool get isOpen => _db != null;

  @override
  Future<void> open([GeneratedDatabase db]) async {
    final dbVersion = db.schemaVersion;
    assert(dbVersion >= 1, 'Database schema version needs to be at least 1');

    final module = await initSqlJs();
    final restored = _restoreDb();
    _db = module.createDatabase(restored);
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    for (var stmt in statements) {
      final prepared = _db.prepare(stmt.sql);

      for (var args in stmt.variables) {
        prepared
          ..executeWith(args)
          ..step();
      }
    }
    return _handlePotentialUpdate();
  }

  @override
  Future<void> runCustom(String statement, List args) {
    _db.runWithArgs(statement, args);
    return Future.value();
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    _db.runWithArgs(statement, args);
    final insertId = _db.lastInsertId();
    await _handlePotentialUpdate();
    return insertId;
  }

  @override
  Future<QueryResult> runSelect(String statement, List args) {
    // todo at least for stream queries we should cache prepared statements.
    final stmt = _db.prepare(statement)..executeWith(args);

    List<String> columnNames;
    final rows = <List<dynamic>>[];

    while (stmt.step()) {
      columnNames ??= stmt.columnNames();
      rows.add(stmt.currentRow());
    }

    columnNames ??= []; // assume no column names when there were no rows

    stmt.free();
    return Future.value(QueryResult(columnNames, rows));
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    _db.runWithArgs(statement, args);
    return _handlePotentialUpdate();
  }

  @override
  Future<void> close() {
    _storeDb();
    _db?.close();
    return Future.value();
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

  Uint8List _restoreDb() {
    final raw = window.localStorage[_persistenceKey];
    if (raw != null) {
      return bin2str.decode(raw);
    }
    return null;
  }

  void _storeDb() {
    if (!isInTransaction) {
      final data = _db.export();
      final binStr = bin2str.encode(data);
      window.localStorage[_persistenceKey] = binStr;
    }
  }
}

class _WebVersionDelegate extends DynamicVersionDelegate {
  String get _versionKey => 'moor_db_version_$name';
  final String name;

  _WebVersionDelegate(this.name);

  @override
  Future<int> get schemaVersion async {
    if (!window.localStorage.containsKey(_versionKey)) {
      return null;
    }
    final versionStr = window.localStorage[_versionKey];

    return int.tryParse(versionStr);
  }

  @override
  Future<void> setSchemaVersion(int version) {
    window.localStorage[_versionKey] = version.toString();
    return Future.value();
  }
}
