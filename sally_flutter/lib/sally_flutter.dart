/// Flutter implementation for the sally database. This library merely provides
/// a thin level of abstraction between the
/// [sqflite](https://pub.dartlang.org/packages/sqflite) library and
/// [sally](https://github.com/simolus3/sally)
library sally_flutter;

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:sally/sally.dart';
import 'package:sqflite/sqflite.dart';

export 'package:sally_flutter/src/animated_list_old.dart';
export 'package:sally/sally.dart' hide Column;

/// A query executor that uses sqlfite internally.
class FlutterQueryExecutor extends QueryExecutor {
  final bool _inDbPath;
  final String path;

  final bool logStatements;

  Database _db;

  FlutterQueryExecutor({@required this.path, this.logStatements})
      : _inDbPath = false;

  FlutterQueryExecutor.inDatabaseFolder(
      {@required this.path, this.logStatements})
      : _inDbPath = true;

  @override
  Future<bool> ensureOpen() async {
    if (_db != null && _db.isOpen) {
      return true;
    }

    String resolvedPath;
    if (_inDbPath) {
      resolvedPath = join(await getDatabasesPath(), path);
    } else {
      resolvedPath = path;
    }

    _db = await openDatabase(
      resolvedPath,
      version: databaseInfo.schemaVersion,
      onCreate: (db, version) {
        return databaseInfo.handleDatabaseCreation(
          executor: (sql) => db.execute(sql),
        );
      },
      onUpgrade: (db, from, to) {
        return databaseInfo.handleDatabaseVersionChange(
            executor: (sql) => db.execute(sql), from: from, to: to);
      },
    );

    return true;
  }

  void _log(String sql, List args) {
    if (logStatements) {
      final formattedArgs = (args?.isEmpty ?? true) ? ' no variables' : args;
      print('Sally: $sql with $formattedArgs');
    }
  }

  @override
  Future<int> runDelete(String statement, List args) {
    _log(statement, args);
    return _db.rawDelete(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    _log(statement, args);
    return _db.rawInsert(statement, args);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    _log(statement, args);
    return _db.rawQuery(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    _log(statement, args);
    return _db.rawUpdate(statement, args);
  }

  @override
  Future<void> runCustom(String statement) {
    _log(statement, null);
    return _db.execute(statement);
  }
}
