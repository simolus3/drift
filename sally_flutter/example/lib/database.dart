import 'dart:async';
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

class CategoryWithCount {
  final Category category;
  final int count; // amount of entries in this category

  CategoryWithCount(this.category, this.count);
}

@UseSally(tables: [Todos, Categories])
class Database extends _$Database {
  Database()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: 'db.sqlite', logStatements: true));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        return m.createAllTables();
      }, onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.addColumn(todos, todos.targetDate);
        }
      });

  Stream<List<CategoryWithCount>> categoriesWithCount() {
    // select all categories and load how many associated entries there are for
    // each category
    return customSelectStream(
        'SELECT *, (SELECT COUNT(*) FROM todos WHERE category = c.id) AS "amount" FROM categories c;',
        readsFrom: Set.of([todos, categories])).map((rows) {
      // when we have the result set, map each row to the data class
      return rows
          .map((row) => CategoryWithCount(Category.fromData(row.data, this), row.readInt('amount')))
          .toList();
    });
  }

  Stream<List<TodoEntry>> allEntries() {
    return select(todos).watch();
  }

  Future addEntry(TodoEntry entry) {
    return into(todos).insert(entry);
  }

  Future deleteEntry(TodoEntry entry) {
    return (delete(todos)..where((t) => t.id.equals(entry.id))).go();
  }
}
