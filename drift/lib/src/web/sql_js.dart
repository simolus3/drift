import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('initSqlJs')
external JSPromise<_SqlJs> _initSqlJs();

Completer<SqlJsModule>? _moduleCompleter;

/// Calls the `initSqlJs` function from the native sql.js library.
Future<SqlJsModule> initSqlJs() {
  if (_moduleCompleter != null) {
    return _moduleCompleter!.future;
  }

  final completer = _moduleCompleter = Completer();
  if (!globalContext.has('initSqlJs')) {
    completer.completeError(UnsupportedError(
        'Could not access the sql.js javascript library. '
        'The drift documentation contains instructions on how to setup drift '
        'the web, which might help you fix this.'));
  } else {
    completer.complete((_initSqlJs().toDart).then(SqlJsModule._));
  }

  return _moduleCompleter!.future;
}

extension type _SqlJs._(JSObject _) implements JSObject {
  @JS('Database')
  external JSFunction get database;
}

extension type _SqlJsDatabase._(JSObject _) implements JSObject {
  external int getRowsModified();

  @JS('run')
  external void runNoArgs(JSString sql);
  external void run(JSString sql, JSArray<JSAny?>? args);

  @JS('exec')
  external JSArray<_QueryExecResult> execNoArgs(JSString sql);
  external JSArray<_QueryExecResult> exec(JSString sql, JSArray<JSAny?> params);
  external _SqlJsStatement prepare(JSString sql);

  external JSUint8Array export();
  external void close();
}

extension type _QueryExecResult._(JSObject _) implements JSObject {
  external JSArray<JSString> get columns;
  external JSArray<JSArray<JSAny?>> get values;
}

@anonymous
extension type _SqlJsStatementGetOptions._(JSObject _) implements JSObject {
  external factory _SqlJsStatementGetOptions({required bool useBigInt});
}

@JS()
extension type _SqlJsStatement._(JSObject _) implements JSObject {
  external void bind(JSArray<JSAny?> values);
  external JSBoolean step();
  external JSArray<JSAny?> get(
      JSObject? params, _SqlJsStatementGetOptions? config);
  external JSArray<JSString> getColumnNames();
  external void free();
}

/// `sql.js` module from the underlying library
class SqlJsModule {
  final _SqlJs _obj;
  SqlJsModule._(this._obj);

  /// Constructs a new [SqlJsDatabase], optionally from the [data] blob.
  SqlJsDatabase createDatabase([Uint8List? data]) {
    final dbObj = _createInternally(data);
    assert(() {
      // set the window.db variable to make debugging easier
      globalContext['db'] = dbObj;
      return true;
    }());

    return SqlJsDatabase._(dbObj);
  }

  _SqlJsDatabase _createInternally(Uint8List? data) {
    if (data != null) {
      return _obj.database.callAsConstructor(data.toJS);
    } else {
      return _obj.database.callAsConstructor();
    }
  }
}

@JS('BigInt')
external JSBigInt _bigInt(JSString s);

JSArray<JSAny?> _replaceDartBigInts(List<Object?> dartList) {
  return [
    for (final arg in dartList)
      if (arg is BigInt)
        _bigInt(arg.checkRange.toString().toJS)
      else
        arg.jsify()
  ].toJS;
}

/// Dart wrapper around a sql database provided by the sql.js library.
class SqlJsDatabase {
  final _SqlJsDatabase _obj;
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
    return PreparedStatement._(_obj.prepare(sql.toJS));
  }

  /// Calls `run(sql)` on the underlying js api
  void run(String sql) {
    _obj.runNoArgs(sql.toJS);
  }

  /// Calls `run(sql, args)` on the underlying js api
  void runWithArgs(String sql, List<dynamic> args) {
    if (args.isEmpty) {
      // Call run without providing arguments. sql.js will then use sqlite3_exec
      // internally, which supports running multiple statements at once. This
      // matches the behavior from a `NativeDatabase`.
      _obj.runNoArgs(sql.toJS);
    } else {
      _obj.run(sql.toJS, _replaceDartBigInts(args));
    }
  }

  /// Returns the amount of rows affected by the most recent INSERT, UPDATE or
  /// DELETE statement.
  int lastModifiedRows() => _obj.getRowsModified();

  /// The row id of the last inserted row. This counter is reset when calling
  /// [export].
  int lastInsertId() {
    // load insert id. Will return [{columns: [...], values: [[id]]}]
    return _selectSingleRowAndColumn('SELECT last_insert_rowid();') as int;
  }

  dynamic _selectSingleRowAndColumn(String sql) {
    final results = _obj.execNoArgs(sql.toJS);
    final result = results.toDart.first;
    final row = result.values.toDart.first.toDart;

    return row.first.dartify();
  }

  /// Runs `export` on the underlying js api
  Uint8List export() => _obj.export().toDart;

  /// Runs `close` on the underlying js api
  void close() => _obj.close();
}

/// Dart api wrapping an underlying prepared statement object from the sql.js
/// library.
class PreparedStatement {
  final _SqlJsStatement _obj;
  PreparedStatement._(this._obj);

  /// Executes this statement with the bound [args].
  void executeWith(List<dynamic> args) => _obj.bind(_replaceDartBigInts(args));

  /// Performs `step` on the underlying js api
  bool step() => _obj.step().toDart;

  /// Reads the current from the underlying js api
  List<dynamic> currentRow([bool useBigInt = false]) {
    if (useBigInt) {
      final result =
          _obj.get(null, _SqlJsStatementGetOptions(useBigInt: true)).toDart;
      final dartResult = <Object?>[];

      for (var i = 0; i < result.length; i++) {
        if (result[i].typeofEquals('bigint')) {
          final toString =
              (result[i] as JSObject).callMethod<JSString>('toString'.toJS);
          dartResult.add(BigInt.parse(toString.toDart));
        } else {
          dartResult.add(result[i].dartify());
        }
      }
      return dartResult;
    } else {
      return _obj.get(null, null).dartify() as List;
    }
  }

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() =>
      _obj.getColumnNames().toDart.map((e) => e.toDart).toList();

  /// Calls `free` on the underlying js api
  void free() => _obj.free();
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
