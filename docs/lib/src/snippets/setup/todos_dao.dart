import 'package:drift/drift.dart';
import 'database.dart';

// #docregion snippet
part 'todos_dao.g.dart';

// the _TodosDaoMixin will be created by drift. It contains all the necessary
// fields for the tables. The <MyDatabase> type annotation is the database class
// that should use this dao.
@DriftAccessor(tables: [TodoItems])
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  TodosDao(super.attachedDatabase);

  Stream<List<TodoItem>> findTodos(String? contentFilter) {
    final query = select(todoItems);
    if (contentFilter case final filter?) {
      query.where((item) => item.content.contains(filter));
    }

    return query.watch();
  }
}

// #enddocregion snippet
