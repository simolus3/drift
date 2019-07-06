import 'dart:async';
import 'dart:js';

import 'dart:typed_data';

// We write our own mapping code to js instead of depending on package:js
// This way, projects using moor can run on flutter as long as they don't import
// this file.

Completer<SqlJsModule> _moduleCompleter;

Future<SqlJsModule> initSqlJs() {
  if (_moduleCompleter != null) {
    return _moduleCompleter.future;
  }

  _moduleCompleter = Completer();
  if (!context.hasProperty('initSqlJs')) {
    return Future.error(
        UnsupportedError('Could not access the sql.js javascript library. '
            'The moor documentation contains instructions on how to setup moor '
            'the web, which might help you fix this.'));
  }

  (context.callMethod('initSqlJs') as JsObject)
      .callMethod('then', [_handleModuleResolved]);

  return _moduleCompleter.future;
}

// We're extracting this into its own method so that we don't have to call
// [allowInterop] on this method or a lambda.
// todo figure out why dart2js generates invalid js when wrapping this in
// allowInterop
void _handleModuleResolved(dynamic module) {
  _moduleCompleter.complete(SqlJsModule._(module as JsObject));
}

class SqlJsModule {
  final JsObject _obj;
  SqlJsModule._(this._obj);

  SqlJsDatabase createDatabase([Uint8List data]) {
    final dbObj = _createInternally(data);
    assert(() {
      // set the window.db variable to make debugging easier
      context['db'] = dbObj;
      return true;
    }());

    return SqlJsDatabase._(dbObj);
  }

  JsObject _createInternally(Uint8List data) {
    final constructor = _obj['Database'] as JsFunction;

    if (data != null) {
      return JsObject(constructor, [data]);
    } else {
      return JsObject(constructor);
    }
  }
}

class SqlJsDatabase {
  final JsObject _obj;
  SqlJsDatabase._(this._obj);

  PreparedStatement prepare(String sql) {
    final obj = _obj.callMethod('prepare', [sql]) as JsObject;
    return PreparedStatement._(obj);
  }

  void run(String sql) {
    _obj.callMethod('run', [sql]);
  }

  void runWithArgs(String sql, List<dynamic> args) {
    final ar = JsArray.from(args);
    _obj.callMethod('run', [sql, ar]);
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
    final results = _obj
        .callMethod('exec', const ['SELECT last_insert_rowid();']) as JsArray;
    final row = results.first as JsObject;
    final data = (row['values'] as JsArray).first as JsArray;

    return data.first as int;
  }

  Uint8List export() {
    return _obj.callMethod('export') as Uint8List;
  }
}

class PreparedStatement {
  final JsObject _obj;
  PreparedStatement._(this._obj);

  /// Executes this statement with the bound [args].
  void executeWith(List<dynamic> args) {
    _obj.callMethod('bind', [JsArray.from(args)]);
  }

  bool step() {
    return _obj.callMethod('step') as bool;
  }

  List<dynamic> currentRow() {
    return _obj.callMethod('get') as JsArray;
  }

  /// The columns returned by this statement. This will only be available after
  /// [step] has been called once.
  List<String> columnNames() {
    return (_obj.callMethod('getColumnNames') as JsArray).cast<String>();
  }

  void free() {
    _obj.callMethod('free');
  }
}
