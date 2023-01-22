import 'package:drift/drift.dart';

import 'example.drift.dart';

class DartExample extends ExampleDrift {
  DartExample(GeneratedDatabase attachedDatabase) : super(attachedDatabase);

  // #docregion watchInCategory
  Stream<List<Todo>> watchInCategory(int category) {
    return filterTodos((todos) => todos.category.equals(category)).watch();
  }
  // #enddocregion watchInCategory
}
