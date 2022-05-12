@JS()
import 'dart:async';
import 'dart:js';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('initSqlJs')
external Object /*Promise<_SqlJs>*/ _initSqlJs();

@JS('undefined')
external Null get _undefined;

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
    completer
        .complete(promiseToFuture<_SqlJs>(_initSqlJs()).then(SqlJsModule._));
  }

  return _moduleCompleter!.future;
}

@JS()
@anonymous
class _SqlJs {
  // ignore: non_constant_identifier_names
  external Object get Database;
}

@JS()
@anonymous
class _SqlJsDatabase {
  external int getRowsModified();

  external void run(String sql, List<Object?>? args);
  external List<_QueryExecResult> exec(String sql, List<Object?>? params);
  external _SqlJsStatement prepare(String sql);

  external Uint8List export();
  external void close();
}

@JS()
@anonymous
class _QueryExecResult {
  external List<String> get columns;
  external List<List<Object?>> get values;
}

@JS()
@anonymous
class _SqlJsStatement {
  external void bind(List<Object?> values);
  external bool step();
  external List<Object?> get(Object? params, dynamic config);
  external List<String> getColumnNames();
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
      context['db'] = dbObj;
      return true;
    }());

    return SqlJsDatabase._(dbObj);
  }

  _SqlJsDatabase _createInternally(Uint8List? data) {
    if (data != null) {
      return callConstructor<_SqlJsDatabase>(_obj.Database, [data]);
    } else {
      return callConstructor<_SqlJsDatabase>(_obj.Database, const []);
    }
  }
}

@JS('BigInt')
external Object _bigInt(Object s);

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
    return PreparedStatement._(_obj.prepare(sql));
  }

  /// Calls `run(sql)` on the underlying js api
  void run(String sql) {
    _obj.run(sql, _undefined);
  }

  /// Calls `run(sql, args)` on the underlying js api
  void runWithArgs(String sql, List<dynamic> args) {
    if (args.isEmpty) {
      // Call run without providing arguments. sql.js will then use sqlite3_exec
      // internally, which supports running multiple statements at once. This
      // matches the behavior from a `NativeDatabase`.
      _obj.run(sql, _undefined);
    } else {
      _obj.run(
          sql,
          args.map((e) {
            if (e != null && e is BigInt) {
              return _bigInt(e.checkRange.toString());
            } else {
              return e;
            }
          }).toList());
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
    final results = _obj.exec(sql, _undefined);
    final result = results.first;
    final row = result.values.first;

    return row.first;
  }

  /// Runs `export` on the underlying js api
  Uint8List export() => _obj.export();

  /// Runs `close` on the underlying js api
  void close() => _obj.close();
}

/// Dart api wrapping an underlying prepared statement object from the sql.js
/// library.
class PreparedStatement {
  final _SqlJsStatement _obj;
  PreparedStatement._(this._obj);

  /// Executes this statement with the bound [args].
  void executeWith(List<dynamic> args) => _obj.bind(args);

  /// Performs `step` on the underlying js api
  bool step() => _obj.step();

  /// Reads the current from the underlying js api
  List<dynamic> currentRow([bool useBigInt = false]) =>
      _obj.get(null, jsify({'useBigInt': useBigInt}));

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() => _obj.getColumnNames();

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
