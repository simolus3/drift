import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

part 'main.g.dart';

@DataClassName('TodoCategory')
class TodoCategories extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text();
}

@DriftDatabase(tables: [TodoCategories])
final class Database extends _$Database {
  Database(super.implementation);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final db = Database(
    SqliteConnection.synchronous(open: () => sqlite3.openInMemory()),
  );

  await db
      .into(db.todoCategories)
      .insert(TodoCategoriesCompanion.insert(name: 'First category'));

  print(await db.select(db.todoCategories).get());
  await db.close();
}
