import 'dart:async';

import 'package:moor_example/database/database.dart';

class TodoAppBloc {
  final Database db;
  Stream<List<TodoEntry>> get allEntries => db.allEntries();

  TodoAppBloc() : db = Database();

  void addEntry(TodoEntry entry) {
    db.addEntry(entry);
  }
}
