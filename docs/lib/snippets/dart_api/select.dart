import 'package:drift/drift.dart';

import '../_shared/todo_tables.dart';
import '../_shared/todo_tables.drift.dart';

// #docregion joinIntro
// We define a data class to contain both a todo entry and the associated
// category.
class EntryWithCategory {
  EntryWithCategory(this.entry, this.category);

  final TodoItem entry;
  final Category? category;
}

// #enddocregion joinIntro

extension SelectExamples on CanUseCommonTables {
  // #docregion limit
  Future<List<TodoItem>> limitTodos(int limit, {int? offset}) {
    return (select(todoItems)..limit(limit, offset: offset)).get();
  }
  // #enddocregion limit

  // #docregion order-by
  Future<List<TodoItem>> sortEntriesAlphabetically() {
    return (select(todoItems)
          ..orderBy([(t) => OrderingTerm(expression: t.title)]))
        .get();
  }
  // #enddocregion order-by

  // #docregion single
  Stream<TodoItem> entryById(int id) {
    return (select(todoItems)..where((t) => t.id.equals(id))).watchSingle();
  }
  // #enddocregion single

  // #docregion mapping
  Stream<List<String>> contentWithLongTitles() {
    final query = select(todoItems)
      ..where((t) => t.title.length.isBiggerOrEqualValue(16));

    return query.map((row) => row.content).watch();
  }
  // #enddocregion mapping

  // #docregion selectable
  // Exposes `get` and `watch`
  MultiSelectable<TodoItem> pageOfTodos(int page, {int pageSize = 10}) {
    return select(todoItems)..limit(pageSize, offset: page);
  }

  // Exposes `getSingle` and `watchSingle`
  SingleSelectable<TodoItem> selectableEntryById(int id) {
    return select(todoItems)..where((t) => t.id.equals(id));
  }

  // Exposes `getSingleOrNull` and `watchSingleOrNull`
  SingleOrNullSelectable<TodoItem> entryFromExternalLink(int id) {
    return select(todoItems)..where((t) => t.id.equals(id));
  }
  // #enddocregion selectable

  // #docregion joinIntro
  // in the database class, we can then load the category for each entry
  Stream<List<EntryWithCategory>> entriesWithCategory() {
    final query = select(todoItems).join([
      leftOuterJoin(categories, categories.id.equalsExp(todoItems.category)),
    ]);

    // see next section on how to parse the result
    // #enddocregion joinIntro
    // #docregion results
    return query.watch().map((rows) {
      return rows.map((row) {
        return EntryWithCategory(
          row.readTable(todoItems),
          row.readTableOrNull(categories),
        );
      }).toList();
    });
    // #enddocregion results
    // #docregion joinIntro
  }
// #enddocregion joinIntro

  // #docregion otherTodosInSameCategory
  /// Searches for todo entries in the same category as the ones having
  /// `titleQuery` in their titles.
  Future<List<TodoItem>> otherTodosInSameCategory(String titleQuery) async {
    // Since we're adding the same table twice (once to filter for the title,
    // and once to find other todos in same category), we need a way to
    // distinguish the two tables. So, we're giving one of them a special name:
    final otherTodos = alias(todoItems, 'inCategory');

    final query = select(otherTodos).join([
      // In joins, `useColumns: false` tells drift to not add columns of the
      // joined table to the result set. This is useful here, since we only join
      // the tables so that we can refer to them in the where clause.
      innerJoin(categories, categories.id.equalsExp(otherTodos.category),
          useColumns: false),
      innerJoin(todoItems, todoItems.category.equalsExp(categories.id),
          useColumns: false),
    ])
      ..where(todoItems.title.contains(titleQuery));

    return query.map((row) => row.readTable(otherTodos)).get();
  }
  // #enddocregion otherTodosInSameCategory

  // #docregion countTodosInCategories
  Future<void> countTodosInCategories() async {
    final amountOfTodos = todoItems.id.count();

    final query = select(categories).join([
      innerJoin(
        todoItems,
        todoItems.category.equalsExp(categories.id),
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
    final avgLength = todoItems.content.length.avg();
    final query = selectOnly(todoItems)..addColumns([avgLength]);

    return query.map((row) => row.read(avgLength)!).watchSingle();
  }
  // #enddocregion averageItemLength

  // #docregion createCategoryForUnassignedTodoEntries
  Future<void> createCategoryForUnassignedTodoEntries() async {
    final newDescription = Variable<String>('category for: ') + todoItems.title;
    final query = selectOnly(todoItems)
      ..where(todoItems.category.isNull())
      ..addColumns([newDescription]);

    await into(categories).insertFromSelect(query, columns: {
      categories.name: newDescription,
    });
  }
  // #enddocregion createCategoryForUnassignedTodoEntries

  // #docregion subquery
  Future<List<(Category, int)>> amountOfLengthyTodoItemsPerCategory() async {
    final longestTodos = Subquery(
      select(todoItems)
        ..orderBy([(row) => OrderingTerm.desc(row.title.length)])
        ..limit(10),
      's',
    );

    // In the main query, we want to count how many entries in longestTodos were
    // found for each category. But we can't access todos.title directly since
    // we're not selecting from `todos`. Instead, we'll use Subquery.ref to read
    // from a column in a subquery.
    final itemCount = longestTodos.ref(todoItems.title).count();
    final query = select(categories).join(
      [
        innerJoin(
          longestTodos,
          // Again using .ref() here to access the category in the outer select
          // statement.
          longestTodos.ref(todoItems.category).equalsExp(categories.id),
          useColumns: false,
        )
      ],
    )
      ..addColumns([itemCount])
      ..groupBy([categories.id]);

    final rows = await query.get();

    return [
      for (final row in rows) (row.readTable(categories), row.read(itemCount)!),
    ];
  }
  // #enddocregion subquery

  // #docregion custom-columns
  Future<List<(TodoItem, bool)>> loadEntries() {
    // assume that an entry is important if it has the string "important" somewhere in its content
    final isImportant = todoItems.content.like('%important%');

    return select(todoItems).addColumns([isImportant]).map((row) {
      final entry = row.readTable(todoItems);
      final entryIsImportant = row.read(isImportant)!;

      return (entry, entryIsImportant);
    }).get();
  }
  // #enddocregion custom-columns
}
