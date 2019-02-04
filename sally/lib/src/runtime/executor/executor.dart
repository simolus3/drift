import 'package:sally/sally.dart';
import 'package:sally/src/runtime/executor/type_system.dart';
import 'package:sally/src/runtime/statements/select.dart';

/// A base class for all generated databases.
abstract class GeneratedDatabase {
  final SqlTypeSystem typeSystem;
  final QueryExecutor executor;

  GeneratedDatabase(this.typeSystem, this.executor);

  SelectStatement<Table, ReturnType> select<Table, ReturnType>(
      TableInfo<Table, ReturnType> table) {
    return SelectStatement<Table, ReturnType>(this, table);
  }
}

abstract class QueryExecutor {
  Future<bool> ensureOpen();
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args);
  List<int> runCreate(String statement, List<dynamic> args);
  Future<int> runUpdate(String statement, List<dynamic> args);
  Future<int> runDelete(String statement, List<dynamic> args);
}
