import 'common/escape.dart';

abstract class SqlDialect {
  DialectCapabilities get capabilites;

  Set<String> get keywords => baseKeywords;

  Object? mapToSqlVariable(Object? dart);
  String mapToSqlLiteral(Object? dart);
  String indexedVariable(int? index);

  Object? mapToDart(Object? sql);
}

class DialectCapabilities {
  final bool supportsAnonymousVariables;
  final bool supportsNullVariables;

  DialectCapabilities({
    this.supportsAnonymousVariables = false,
    this.supportsNullVariables = false,
  });
}
