import 'package:convert/convert.dart';

import '../dialect.dart';

import '../src/common/escape.dart';
import '' as self;

final dialect = Sqlite3Dialect._();

const SqlType<String> text = _SqliteType('TEXT');
const SqlType<int> integer = _SqliteType('INTEGER');
const SqlType<double> real = _SqliteType('REAL');
const SqlType<List<int>> blob = _SqliteType('BLOB');

class Sqlite3Dialect implements SqlDialect {
  Sqlite3Dialect._();

  @override
  DialectCapabilities capabilites = DialectCapabilities(
    supportsAnonymousVariables: true,
    supportsNullVariables: true,
  );

  @override
  String indexedVariable(int? index) {
    if (index == null) {
      return '?';
    } else {
      return '?$index';
    }
  }

  @override
  Object? mapToDart(Object? sql) => sql;

  @override
  String mapToSqlLiteral(Object? dart) {
    if (dart == null) {
      return 'NULL';
    } else if (dart is String) {
      return sqlStringLiteral(dart);
    } else if (dart is num) {
      return dart.toString();
    } else if (dart is List<int>) {
      return 'x${hex.encode(dart)}';
    } else {
      throw ArgumentError.value(dart, 'dart', 'Unknown type for SQL literal');
    }
  }

  @override
  Object? mapToSqlVariable(Object? dart) => dart;
}

class _SqliteType<T> implements SqlType<T> {
  const _SqliteType(this.name);

  @override
  SqlDialect get dialect => self.dialect;

  @override
  final String name;
}
