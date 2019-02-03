class UseData {
  final List<Type> tables;
  final int schemaVersion;

  const UseData({this.tables, this.schemaVersion = 1});
}

abstract class QueryExecutor {
  Future<List<Map<String, dynamic>>> executeQuery(String sql, [dynamic params]);
}

abstract class SallyDb {}
