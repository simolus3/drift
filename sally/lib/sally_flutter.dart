/// Flutter implementation for the sally database. This library merely provides
/// a thin level of abstraction between the
/// [sqflite](https://pub.dartlang.org/packages/sqflite) library and
/// [sally](https://github.com/simolus3/sally)
library sally_flutter;

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:sally/sally.dart';
import 'package:sqflite/sqflite.dart';

/// A query executor that uses sqlfite internally.
class FlutterQueryExecutor extends QueryExecutor {
  final bool _inDbPath;
  final String path;
  Database _db;

  FlutterQueryExecutor({@required this.path}) : _inDbPath = false;

  FlutterQueryExecutor.inDatabaseFolder(this.path) : _inDbPath = true;

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

  @override
  Future<int> runDelete(String statement, List args) {
    return _db.rawDelete(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    return _db.rawInsert(statement, args);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    return _db.rawQuery(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return _db.rawUpdate(statement, args);
  }

  @override
  Future<void> runCustom(String statement) {
    return _db.execute(statement);
  }
}
