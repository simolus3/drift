import 'dart:async';

import 'package:sally/sally.dart';
import 'database.dart';

part 'todos_dao.g.dart';

@UseDao(tables: [Todos])
class TodosDao extends DatabaseAccessor<Database> with _TodosDaoMixin {
  TodosDao(Database db) : super(db);

  Stream<List<TodoEntry>> todosWithoutCategory() {
    return null;
  }

}