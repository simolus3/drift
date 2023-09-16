---
data:
  title: "DAOs"
  description: Keep your database code modular with DAOs
path: /docs/advanced-features/daos/
aliases:
  - /daos/
template: layouts/docs/single
---

When you have a lot of queries, putting them all into one class might become
tedious. You can avoid this by extracting some queries into classes that are
available from your main database class. Consider the following code:

```dart
part 'todos_dao.g.dart';

// the _TodosDaoMixin will be created by drift. It contains all the necessary
// fields for the tables. The <MyDatabase> type annotation is the database class
// that should use this dao.
@DriftAccessor(tables: [Todos])
class TodosDao extends DatabaseAccessor<MyDatabase> with _$TodosDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  TodosDao(MyDatabase db) : super(db);

  Stream<List<TodoEntry>> todosInCategory(Category category) {
    if (category == null) {
      return (select(todos)..where((t) => isNull(t.category))).watch();
    } else {
      return (select(todos)..where((t) => t.category.equals(category.id)))
          .watch();
    }
  }
}
```

If we now change the annotation on the `MyDatabase` class to `@DriftDatabase(tables: [Todos, Categories], daos: [TodosDao])`
and re-run the code generation, a generated getter `todosDao` can be used to access the instance of that dao.
