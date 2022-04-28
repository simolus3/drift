import 'package:convert/convert.dart';

import '../dialect.dart';

import '../src/common/escape.dart';
import 'common.dart';
import '' as self;

final dialect = MySqlDialect._();

const SqlType<String> text = _MysqlType('TEXT');
const SqlType<int> integer = _MysqlType('INTEGER');
const SqlType<double> real = _MysqlType('REAL');
const SqlType<List<int>> blob = _MysqlType('BLOB');

SqlType<String> char(int length) => _MysqlType('CHAR($length)');

SqlType<String> varchar(int length) => _MysqlType('VARCHAR($length)');

class MySqlDialect extends CommonSqlDialect {
  MySqlDialect._();

  @override
  SqlType typeFor(CommonSqlType kind) {
    switch (kind) {
      case CommonSqlType.text:
        return text;
      case CommonSqlType.integer:
        return integer;
      case CommonSqlType.real:
        return real;
      case CommonSqlType.blob:
        return blob;
    }
  }

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

class _MysqlType<T> implements SqlType<T> {
  const _MysqlType(this.name);

  @override
  SqlDialect get dialect => self.dialect;

  @override
  final String name;
}
