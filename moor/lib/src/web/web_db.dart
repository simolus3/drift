part of 'package:moor/moor_web.dart';

/// Signature of a function that asynchronously initializes a web database if it
/// doesn't exist.
/// The bytes returned should represent a valid sqlite3 database file.
typedef CreateWebDatabase = Future<Uint8List> Function();

/// Experimental moor backend for the web. To use this platform, you need to
/// include the latest version of `sql.js` in your html.
class WebDatabase extends DelegatedDatabase {
  /// A database executor that works on the web.
  ///
  /// [name] can be used to identify multiple databases. The optional
  /// [initializer] can be used to initialize the database if it doesn't exist.
  WebDatabase(String name,
      {bool logStatements = false, CreateWebDatabase initializer})
      : super(_WebDelegate(name, initializer),
            logStatements: logStatements, isSequential: true);
}

class _WebDelegate extends DatabaseDelegate {
  final String name;
  final CreateWebDatabase initializer;
  SqlJsDatabase _db;

  String get _persistenceKey => 'moor_db_str_$name';

  bool _inTransaction = false;

  _WebDelegate(this.name, this.initializer);

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
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  DbVersionDelegate get versionDelegate =>
      _versionDelegate ??= _WebVersionDelegate(this);
  DbVersionDelegate _versionDelegate;

  @override
  bool get isOpen => _db != null;

  @override
  Future<void> open([GeneratedDatabase db]) async {
    final dbVersion = db.schemaVersion;
    assert(dbVersion >= 1, 'Database schema version needs to be at least 1');

    final module = await initSqlJs();
    var restored = _restoreDb();

    if (restored == null && initializer != null) {
      restored = await initializer();
      _storeData(restored);
    }

    _db = module.createDatabase(restored);
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    for (final stmt in statements) {
      final prepared = _db.prepare(stmt.sql);

      for (final args in stmt.variables) {
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

  @override
  void notifyDatabaseOpened(OpeningDetails details) {
    if (details.hadUpgrade | details.wasCreated) {
      _storeDb();
    }
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
      _storeData(_db.export());
    }
  }

  void _storeData(Uint8List data) {
    final binStr = bin2str.encode(data);
    window.localStorage[_persistenceKey] = binStr;
  }
}

class _WebVersionDelegate extends DynamicVersionDelegate {
  String get _versionKey => 'moor_db_version_${delegate.name}';

  final _WebDelegate delegate;

  _WebVersionDelegate(this.delegate);

  // Note: Earlier moor versions used to store the database version in a special
  // field in local storage (moor_db_version_<name>). Since 2.3, we instead use
  // the user_version pragma, but still need to keep backwards compatibility.

  @override
  Future<int> get schemaVersion async {
    if (!window.localStorage.containsKey(_versionKey)) {
      return delegate._db?.userVersion;
    }
    final versionStr = window.localStorage[_versionKey];

    return int.tryParse(versionStr);
  }

  @override
  Future<void> setSchemaVersion(int version) {
    delegate._db.userVersion = version;
    window.localStorage[_versionKey] = version.toString();
    return Future.value();
  }
}
