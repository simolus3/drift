import 'dart:async';
import 'package:moor_flutter/moor_flutter.dart';

part 'database.g.dart';

@DataClassName('TodoEntry')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get content => text()();

  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get category => integer()
      .nullable()
      .customConstraint('NULLABLE REFERENCES categories(id)')();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().named('desc')();
}

class CategoryWithCount {
  CategoryWithCount(this.category, this.count);

  // can be null, in which case we count how many entries don't have a category
  final Category category;
  final int count; // amount of entries in this category
}

class EntryWithCategory {
  EntryWithCategory(this.entry, this.category);

  final TodoEntry entry;
  final Category category;
}

@UseMoor(tables: [Todos, Categories])
class Database extends _$Database {
  Database()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: 'db.sqlite', logStatements: true));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAllTables();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.addColumn(todos, todos.targetDate);
        }
      },
    );
  }

  Stream<List<CategoryWithCount>> categoriesWithCount() {
    // select all categories and load how many associated entries there are for
    // each category
    return customSelectStream(
      'SELECT c.*, (SELECT COUNT(*) FROM todos WHERE category = c.id) AS amount'
      ' FROM categories c '
      'UNION ALL SELECT null, null, '
      '(SELECT COUNT(*) FROM todos WHERE category IS NULL)',
      readsFrom: {todos, categories},
    ).map((rows) {
      // when we have the result set, map each row to the data class
      return rows.map((row) {
        final hasId = row.data['id'] != null;

        return CategoryWithCount(
          hasId ? Category.fromData(row.data, this) : null,
          row.readInt('amount'),
        );
      }).toList();
    });
  }

  /// Watches all entries in the given [category]. If the category is null, all
  /// entries will be shown instead.
  Stream<List<EntryWithCategory>> watchEntriesInCategory(Category category) {
    final query = select(todos).join(
        [leftOuterJoin(categories, categories.id.equalsExp(todos.category))]);

    if (category != null) {
      query.where(categories.id.equals(category.id));
    } else {
      query.where(isNull(categories.id));
    }

    return query.watch().map((rows) {
      // read both the entry and the associated category for each row
      return rows.map((row) {
        return EntryWithCategory(
          row.readTable(todos),
          row.readTable(categories),
        );
      }).toList();
    });
  }

  Future createEntry(TodoEntry entry) {
    return into(todos).insert(entry);
  }

  /// Updates the row in the database represents this entry by writing the
  /// updated data.
  Future updateEntry(TodoEntry entry) {
    return update(todos).replace(entry);
  }

  Future deleteEntry(TodoEntry entry) {
    return delete(todos).delete(entry);
  }

  Future<int> createCategory(Category category) {
    return into(categories).insert(category);
  }

  Future deleteCategory(Category category) {
    return transaction((t) async {
      await t.customUpdate(
        'UPDATE todos SET category = NULL WHERE category = ?',
        updates: {todos},
        variables: [Variable.withInt(category.id)],
      );

      await t.delete(categories).delete(category);
    });
  }
}
