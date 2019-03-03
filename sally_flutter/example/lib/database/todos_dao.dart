import 'dart:async';

import 'package:sally/sally.dart';
import 'database.dart';

part 'todos_dao.g.dart';

@UseDao(tables: [Todos])
class TodosDao extends DatabaseAccessor<Database> with _TodosDaoMixin {
  TodosDao(Database db) : super(db);

  Stream<List<TodoEntry>> todosInCategory(Category category) {
    if (category == null) {
      return (select(todos)..where((t) => isNull(t.category))).watch();
    } else {
      return (select(todos)..where((t) => t.category.equals(category.id)))
          .watch();
    }
  }
}
