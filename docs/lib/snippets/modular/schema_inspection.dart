import 'package:drift/drift.dart';

import 'drift/example.drift.dart';

// #docregion findById
extension FindById<Table extends HasResultSet, Row>
    on ResultSetImplementation<Table, Row> {
  Selectable<Row> findById(int id) {
    return select()
      ..where((row) {
        final idColumn = columnsByName['id'];

        if (idColumn == null) {
          throw ArgumentError.value(
              this, 'this', 'Must be a table with an id column');
        }

        if (idColumn.type != DriftSqlType.int) {
          throw ArgumentError('Column `id` is not an integer');
        }

        return idColumn.equals(id);
      });
  }
}
// #enddocregion findById

// #docregion updateTitle
extension UpdateTitle on DatabaseConnectionUser {
  Future<Row?> updateTitle<T extends TableInfo<Table, Row>, Row>(
      T table, int id, String newTitle) async {
    final columnsByName = table.columnsByName;
    final stmt = update(table)
      ..where((tbl) {
        final idColumn = columnsByName['id'];

        if (idColumn == null) {
          throw ArgumentError.value(
              this, 'this', 'Must be a table with an id column');
        }

        if (idColumn.type != DriftSqlType.int) {
          throw ArgumentError('Column `id` is not an integer');
        }

        return idColumn.equals(id);
      });

    final rows = await stmt.writeReturning(RawValuesInsertable({
      'title': Variable<String>(newTitle),
    }));

    return rows.singleOrNull;
  }
}
// #enddocregion updateTitle

extension FindTodoEntryById on GeneratedDatabase {
  Todos get todos => Todos(this);

  // #docregion findTodoEntryById
  Selectable<Todo> findTodoEntryById(int id) {
    return select(todos)..where((row) => row.id.equals(id));
  }
  // #enddocregion findTodoEntryById

  // #docregion updateTodo
  Future<Todo?> updateTodoTitle(int id, String newTitle) {
    return updateTitle(todos, id, newTitle);
  }
  // #enddocregion updateTodo
}
