final class QueryProvider<Row> {
  final bool singleRow;

  const QueryProvider({this.singleRow = false});
}

const queryProvider = QueryProvider<dynamic>();
