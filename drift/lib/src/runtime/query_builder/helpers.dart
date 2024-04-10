@internal
library;

import 'package:meta/meta.dart';

import '../types/mapping.dart';
import 'query_builder.dart';

/// Internal utilities for building queries that aren't exported.
extension WriteDefinition on GenerationContext {
  /// Writes the result set to this context, suitable to implement `FROM`
  /// clauses and joins.
  void writeResultSet(ResultSetImplementation resultSet) {
    switch (resultSet) {
      case Subquery(:final select):
        buffer.write('(');
        select.writeInto(this);
        buffer
          ..write(') ')
          ..write(resultSet.aliasedName);
      case TableValuedFunction():
        resultSet.writeInto(this);

        if (resultSet.aliasedName != resultSet.entityName) {
          buffer.write(' ${resultSet.aliasedName}');
        }
      default:
        buffer.write(resultSet.tableWithAlias);
        watchedTables.add(resultSet);
    }
  }

  /// Returns a suitable SQL string in [sql] based on the current dialect.
  String pickForDialect(Map<SqlDialect, String> sql) {
    assert(
      sql.containsKey(dialect),
      'Tried running SQL optimized for the following dialects: ${sql.keys.join}. '
      'However, the database is running $dialect. Has that dialect been added '
      'to the `dialects` drift builder option?',
    );

    final found = sql[dialect];
    if (found != null) {
      return found;
    }

    return sql.values.first; // Fallback
  }
}

/// Utilities to derive other expressions with a type compatible to `this`
/// expression.
extension WithTypes<T extends Object> on Expression<T> {
  /// Creates a variable with a matching [driftSqlType].
  Variable<T> variable(T? value) {
    return switch (driftSqlType) {
      UserDefinedSqlType<T> custom => Variable(value, custom),
      _ => Variable(value),
    };
  }
}
