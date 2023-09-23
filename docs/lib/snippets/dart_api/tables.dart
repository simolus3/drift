import 'package:drift/drift.dart';

// #docregion nnbd
class Items extends Table {
  IntColumn get category => integer().nullable()();
  // ...
}
// #enddocregion nnbd

// #docregion names
@DataClassName('EnabledCategory')
class EnabledCategories extends Table {
  @override
  String get tableName => 'categories';

  @JsonKey('parent_id')
  IntColumn get parentCategory => integer().named('parent')();
}
// #enddocregion names

// #docregion references
class TodoItems extends Table {
  // ...
  IntColumn get category =>
      integer().nullable().references(TodoCategories, #id)();
}

@DataClassName("Category")
class TodoCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  // and more columns...
}
// #enddocregion references

// #docregion unique-column
class TableWithUniqueColumn extends Table {
  IntColumn get unique => integer().unique()();
}
// #enddocregion unique-column

// #docregion primary-key
class GroupMemberships extends Table {
  IntColumn get group => integer()();
  IntColumn get user => integer()();

  @override
  Set<Column> get primaryKey => {group, user};
}
// #enddocregion primary-key

// #docregion unique-table
class IngredientInRecipes extends Table {
  @override
  List<Set<Column>> get uniqueKeys => [
        {recipe, ingredient},
        {recipe, amountInGrams}
      ];

  IntColumn get recipe => integer()();
  IntColumn get ingredient => integer()();

  IntColumn get amountInGrams => integer().named('amount')();
}
// #enddocregion unique-table

// #docregion custom-constraint-table
class TableWithCustomConstraints extends Table {
  IntColumn get foo => integer()();
  IntColumn get bar => integer()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (foo, bar) REFERENCES group_memberships ("group", user)',
      ];
}
// #enddocregion custom-constraint-table

// #docregion index
@TableIndex(name: 'user_name', columns: {#name})
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
// #enddocregion index

// #docregion custom-type
typedef Category = ({int id, String name});

@UseRowClass(Category)
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // #enddocregion custom-type
  @override
  String get tableName => 'categories2';
  // #docregion custom-type
}
// #enddocregion custom-type
