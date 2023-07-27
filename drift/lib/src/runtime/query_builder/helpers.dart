@internal
library;

import 'package:drift/drift.dart';

import 'package:meta/meta.dart';

/// Internal utilities for building queries that aren't exported.
extension WriteDefinition on GenerationContext {
  /// Writes the result set to this context, suitable to implement `FROM`
  /// clauses and joins.
  void writeResultSet(ResultSetImplementation resultSet) {
    if (resultSet is Subquery) {
      buffer.write('(');
      resultSet.select.writeInto(this);
      buffer
        ..write(') ')
        ..write(resultSet.aliasedName);
    } else {
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
