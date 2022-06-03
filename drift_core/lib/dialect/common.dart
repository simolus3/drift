import 'dart:async';

import 'package:drift_core/src/schema.dart';

import 'package:drift_core/src/builder/context.dart';

import '../dialect.dart';
import '' as self;

const _key = #drift_core.dialect.common;

T runWithDialect<T>({
  required CommonSqlDialect dialect,
  required T Function() body,
}) {
  return runZoned(body, zoneValues: {_key: dialect});
}

CommonSqlDialect get _currentDialect {
  final impl = Zone.current[_key];

  if (impl is CommonSqlDialect) {
    return impl;
  }

  throw StateError('This code needs to run in a `runWithDialect` call!');
}

final SqlDialect dialect = _DelegatingDialect();

const SqlType<String> text = _SqliteType(CommonSqlType.text);
const SqlType<int> integer = _SqliteType(CommonSqlType.integer);
const SqlType<double> real = _SqliteType(CommonSqlType.real);
const SqlType<List<int>> blob = _SqliteType(CommonSqlType.blob);

enum CommonSqlType {
  text,
  integer,
  real,
  blob,
}

/// A dialect providing common options.
///
/// This can be implemented by direct SQL implementations to allow users to
/// write queries against a common dialect and choose an appropriate dialect
/// dynamically.
abstract class CommonSqlDialect extends SqlDialect {
  const CommonSqlDialect();

  SqlType typeFor(CommonSqlType kind);
}

class _DelegatingDialect extends SqlDialect {
  const _DelegatingDialect();

  @override
  DialectCapabilities get capabilites => _currentDialect.capabilites;

  @override
  String indexedVariable(int? index) => _currentDialect.indexedVariable(index);

  @override
  Object? mapToDart(Object? sql) => _currentDialect.mapToDart(sql);

  @override
  String mapToSqlLiteral(Object? dart) => _currentDialect.mapToSqlLiteral(dart);

  @override
  Object? mapToSqlVariable(Object? dart) =>
      _currentDialect.mapToSqlVariable(dart);
}

class _SqliteType<T> implements SqlType<T> {
  final CommonSqlType type;

  const _SqliteType(this.type);

  @override
  SqlDialect get dialect => self.dialect;

  @override
  String get name => _currentDialect.typeFor(type).name;
}
