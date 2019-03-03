import 'dart:async';

import 'package:sally/sally.dart';
import 'database.dart';

@UseDao(tables: [Todos])
class TodosDao extends DatabaseAccessor {
  TodosDao(GeneratedDatabase db) : super(db);

  Stream<List<TodoEntry>> todosWithoutCategory() {
    return null;
  }

}