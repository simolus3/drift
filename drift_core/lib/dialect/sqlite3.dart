import 'package:convert/convert.dart';

import '../dialect.dart';

import '../drift_core.dart';
import '../src/common/escape.dart';
import 'common.dart';
import '' as self;

final dialect = Sqlite3Dialect._();

const SqlType<String> text = _SqliteType('TEXT');
const SqlType<int> integer = _SqliteType('INTEGER');
const SqlType<double> real = _SqliteType('REAL');
const SqlType<List<int>> blob = _SqliteType('BLOB');

class Sqlite3Dialect extends CommonSqlDialect {
  Sqlite3Dialect._();

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

  @override
  SqlComponent createTable(SchemaTable table) {
    return _SqliteCreateTableStatement(table);
  }
}

class _SqliteType<T> implements SqlType<T> {
  const _SqliteType(this.name);

  @override
  SqlDialect get dialect => self.dialect;

  @override
  final String name;
}

class _SqliteCreateTableStatement extends SqlComponent {
  final SchemaTable table;

  _SqliteCreateTableStatement(this.table);

  @override
  void writeInto(GenerationContext context) {
    context.buffer
      ..write('CREATE TABLE ')
      ..write(context.identifier(table.tableName))
      ..write('(');

    var first = true;
    for (final column in table.columns) {
      if (!first) {
        context.buffer.write(', ');
      }
      first = false;

      context.buffer
        ..write(context.identifier(column.name))
        ..write(' ')
        ..write(column.type.name);
    }

    context.buffer.write(')');
  }
}
