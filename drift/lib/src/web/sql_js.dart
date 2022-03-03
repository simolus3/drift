import 'dart:async';
import 'dart:js';
import 'dart:typed_data';

// We write our own mapping code to js instead of depending on package:js
// This way, projects using drift can run on flutter as long as they don't
// import this file.

Completer<SqlJsModule>? _moduleCompleter;

/// Calls the `initSqlJs` function from the native sql.js library.
Future<SqlJsModule> initSqlJs() {
  if (_moduleCompleter != null) {
    return _moduleCompleter!.future;
  }

  final completer = _moduleCompleter = Completer();
  if (!context.hasProperty('initSqlJs')) {
    completer.completeError(UnsupportedError(
        'Could not access the sql.js javascript library. '
        'The drift documentation contains instructions on how to setup drift '
        'the web, which might help you fix this.'));
  } else {
    (context.callMethod('initSqlJs') as JsObject)
        .callMethod('then', [allowInterop(_handleModuleResolved)]);
  }

  return _moduleCompleter!.future;
}

// We're extracting this into its own method so that we don't have to call
// [allowInterop] on this method or a lambda.
// todo figure out why dart2js generates invalid js when wrapping this in
// allowInterop
void _handleModuleResolved(dynamic module) {
  _moduleCompleter!.complete(SqlJsModule._(module as JsObject));
}

/// `sql.js` module from the underlying library
class SqlJsModule {
  final JsObject _obj;
  SqlJsModule._(this._obj);

  /// Constructs a new [SqlJsDatabase], optionally from the [data] blob.
  SqlJsDatabase createDatabase([Uint8List? data]) {
    final dbObj = _createInternally(data);
    assert(() {
      // set the window.db variable to make debugging easier
      context['db'] = dbObj;
      return true;
    }());

    return SqlJsDatabase._(dbObj);
  }

  JsObject _createInternally(Uint8List? data) {
    final constructor = _obj['Database'] as JsFunction;

    if (data != null) {
      return JsObject(constructor, [data]);
    } else {
      return JsObject(constructor);
    }
  }
}

/// Dart wrapper around a sql database provided by the sql.js library.
class SqlJsDatabase {
  final JsObject _obj;
  SqlJsDatabase._(this._obj);

  /// Returns the `user_version` pragma from sqlite.
  int get userVersion {
    return _selectSingleRowAndColumn('PRAGMA user_version;') as int;
  }

  /// Sets sqlite's `user_version` pragma to the specified [version].
  set userVersion(int version) {
    run('PRAGMA user_version = $version');
  }

  /// Calls `prepare` on the underlying js api
  PreparedStatement prepare(String sql) {
    final obj = _obj.callMethod('prepare', [sql]) as JsObject;
    return PreparedStatement._(obj);
  }

  /// Calls `run(sql)` on the underlying js api
  void run(String sql) {
    _obj.callMethod('run', [sql]);
  }

  /// Calls `run(sql, args)` on the underlying js api
  void runWithArgs(String sql, List<dynamic> args) {
    if (args.isEmpty) {
      // Call run without providing arguments. sql.js will then use sqlite3_exec
      // internally, which supports running multiple statements at once. This
      // matches the behavior from a `NativeDatabase`.
      _obj.callMethod('run', [sql]);
    } else {
      final ar = JsArray.from(args);
      _obj.callMethod('run', [sql, ar]);
    }
  }

  /// Returns the amount of rows affected by the most recent INSERT, UPDATE or
  /// DELETE statement.
  int lastModifiedRows() {
    return _obj.callMethod('getRowsModified') as int;
  }

  /// The row id of the last inserted row. This counter is reset when calling
  /// [export].
  int lastInsertId() {
    // load insert id. Will return [{columns: [...], values: [[id]]}]
    return _selectSingleRowAndColumn('SELECT last_insert_rowid();') as int;
  }

  dynamic _selectSingleRowAndColumn(String sql) {
    final results = _obj.callMethod('exec', [sql]) as JsArray;
    final row = results.first as JsObject;
    final data = (row['values'] as JsArray).first as JsArray;
    return data.first;
  }

  /// Runs `export` on the underlying js api
  Uint8List export() {
    return _obj.callMethod('export') as Uint8List;
  }

  /// Runs `close` on the underlying js api
  void close() {
    _obj.callMethod('close');
  }
}

/// Dart api wrapping an underlying prepared statement object from the sql.js
/// library.
class PreparedStatement {
  final JsObject _obj;
  PreparedStatement._(this._obj);

  /// Executes this statement with the bound [args].
  void executeWith(List<dynamic> args) {
    _obj.callMethod('bind', [JsArray.from(args)]);
  }

  /// Performs `step` on the underlying js api
  bool step() {
    return _obj.callMethod('step') as bool;
  }

  /// Reads the current from the underlying js api
  List<dynamic> currentRow() {
    return _obj.callMethod('get') as JsArray;
  }

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() {
    return (_obj.callMethod('getColumnNames') as JsArray).cast<String>();
  }

  /// Calls `free` on the underlying js api
  void free() {
    _obj.callMethod('free');
  }
}
