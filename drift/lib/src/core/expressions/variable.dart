import 'package:drift/src/core/dialect.dart';

import 'package:drift/src/core/types.dart';

import 'expression.dart';

final class Variable<T extends Object> extends Expression<T> {
  final T? value;
  final SqlType<T>? knownType;

  Variable(this.value, {this.knownType});

  @override
  SqlType<T> resolveType(DriftDialect dialect) {
    return knownType ?? dialect.resolveType<T>();
  }
}
