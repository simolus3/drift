abstract class SqlDialect {
  DialectCapabilities get capabilites;

  Object? mapToSqlVariable(Object? dart);
  String mapToSqlLiteral(Object? dart);
  String indexedVariable(int? index);

  Object? mapToDart(Object? sql);
}

class DialectCapabilities {
  final bool supportsAnonymousVariables;
  final bool supportsNullVariables;

  DialectCapabilities(
      this.supportsAnonymousVariables, this.supportsNullVariables);
}
