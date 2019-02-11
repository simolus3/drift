import 'package:sally/sally.dart';
import 'package:sqlite2/sqlite.dart';

class MemoryDatabase extends QueryExecutor {
  Database _db;

  @override
  Future<bool> ensureOpen() {
    _db ??= Database.inMemory();
    return Future.value(true);
  }

  @override
  Future<void> runCustom(String statement) {
    return _db.execute(statement);
  }

  @override
  Future<int> runDelete(String statement, List args) {
    return _db.execute(statement,
        params: args.map((x) => x.toString()).toList());
  }

  @override
  Future<int> runInsert(String statement, List args) {
    return runDelete(statement, args);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    return _db
        .query(statement, params: args.map((x) => x.toString()).toList())
        .fold([], (list, row) {
      return list..add(row.toMap());
    });
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return runDelete(statement, args);
  }
}
