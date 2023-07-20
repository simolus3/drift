import 'package:drift/drift.dart';

/// Utilities for writing the definition of a result set into a query.
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
}
