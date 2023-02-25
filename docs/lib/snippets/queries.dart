import 'package:drift/drift.dart';

import 'tables/filename.dart';

// #docregion joinIntro
// We define a data class to contain both a todo entry and the associated
// category.
class EntryWithCategory {
  EntryWithCategory(this.entry, this.category);

  final Todo entry;
  final Category? category;
}

// #enddocregion joinIntro

extension GroupByQueries on MyDatabase {
// #docregion joinIntro
  // in the database class, we can then load the category for each entry
  Stream<List<EntryWithCategory>> entriesWithCategory() {
    final query = select(todos).join([
      leftOuterJoin(categories, categories.id.equalsExp(todos.category)),
    ]);

    // see next section on how to parse the result
    // #enddocregion joinIntro
    // #docregion results
    return query.watch().map((rows) {
      return rows.map((row) {
        return EntryWithCategory(
          row.readTable(todos),
          row.readTableOrNull(categories),
        );
      }).toList();
    });
    // #enddocregion results
    // #docregion joinIntro
  }
// #enddocregion joinIntro

  // #docregion countTodosInCategories
  Future<void> countTodosInCategories() async {
    final amountOfTodos = todos.id.count();

    final query = select(categories).join([
      innerJoin(
        todos,
        todos.category.equalsExp(categories.id),
        useColumns: false,
      )
    ]);
    query
      ..addColumns([amountOfTodos])
      ..groupBy([categories.id]);

    final result = await query.get();

    for (final row in result) {
      print('there are ${row.read(amountOfTodos)} entries in'
          '${row.readTable(categories)}');
    }
  }
  // #enddocregion countTodosInCategories

  // #docregion averageItemLength
  Stream<double> averageItemLength() {
    final avgLength = todos.content.length.avg();
    final query = selectOnly(todos)..addColumns([avgLength]);

    return query.map((row) => row.read(avgLength)!).watchSingle();
  }
  // #enddocregion averageItemLength

  // #docregion otherTodosInSameCategory
  /// Searches for todo entries in the same category as the ones having
  /// `titleQuery` in their titles.
  Future<List<Todo>> otherTodosInSameCategory(String titleQuery) async {
    // Since we're adding the same table twice (once to filter for the title,
    // and once to find other todos in same category), we need a way to
    // distinguish the two tables. So, we're giving one of them a special name:
    final otherTodos = alias(todos, 'inCategory');

    final query = select(otherTodos).join([
      // In joins, `useColumns: false` tells drift to not add columns of the
      // joined table to the result set. This is useful here, since we only join
      // the tables so that we can refer to them in the where clause.
      innerJoin(categories, categories.id.equalsExp(otherTodos.category),
          useColumns: false),
      innerJoin(todos, todos.category.equalsExp(categories.id),
          useColumns: false),
    ])
      ..where(todos.title.contains(titleQuery));

    return query.map((row) => row.readTable(otherTodos)).get();
  }
  // #enddocregion otherTodosInSameCategory

  // #docregion createCategoryForUnassignedTodoEntries
  Future<void> createCategoryForUnassignedTodoEntries() async {
    final newDescription = Variable<String>('category for: ') + todos.title;
    final query = selectOnly(todos)
      ..where(todos.category.isNull())
      ..addColumns([newDescription]);

    await into(categories).insertFromSelect(query, columns: {
      categories.description: newDescription,
    });
  }
  // #enddocregion createCategoryForUnassignedTodoEntries
}
