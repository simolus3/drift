import 'package:sally_flutter/sally_flutter.dart';

part 'database.g.dart';

@DataClassName('TodoEntry')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 4, max: 16).nullable()();

  TextColumn get content => text()();

  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get category => integer().nullable()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().named('desc')();
}

@UseSally(tables: [Todos, Categories])
class Database extends _$Database {
  Database()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: 'db.sqlite', logStatements: true));

  @override
  int get schemaVersion => 1;

  Stream<List<Category>> get definedCategories => select(categories).watch();

  Stream<List<TodoEntry>> todosInCategories(List<Category> categories) {
    final ids = categories.map((c) => c.id);

    return (select(todos)..where((t) => isIn(t.category, ids))).watch();
  }

  Stream<List<TodoEntry>> get todosWithoutCategories =>
      (select(todos)..where((t) => isNull(t.category))).watch();
}
