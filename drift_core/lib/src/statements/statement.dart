import 'package:meta/meta.dart';

import '../builder/context.dart';

import '../schema.dart';
import 'clauses.dart';

abstract class SqlStatement extends SqlComponent {
  @internal
  List<TableInQuery> get primaryTables;
}

class StatementScope extends ContextScope {
  final SqlStatement statement;

  StatementScope(this.statement);

  bool get readsFromMultipleTables => statement.primaryTables.length > 1;

  AddedTable? findTable(EntityWithResult entity, String? name) {
    bool hasMatch(AddedTable table) {
      return table.table == entity && table.as == name;
    }

    for (final joined in statement.primaryTables) {
      if (joined is AddedTable && hasMatch(joined)) {
        return joined;
      } else if (joined is JoinedTable && hasMatch(joined.table)) {
        return joined.table;
      }
    }

    return null;
  }
}
