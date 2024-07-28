// ignore_for_file: invalid_annotation_target, recursive_getters

import 'package:drift/drift.dart';
import 'package:drift_docs/snippets/modular/drift/with_existing.drift.dart';
import 'package:uuid/uuid.dart';

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
  TextColumn get username => text().unique()();
}
// #enddocregion unique-column

// #docregion primary-key
class UuidIdTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};
}
// #enddocregion primary-key

// #docregion unique-table
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {title, author}
      ];
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

class GroupMemberships extends Table {
  IntColumn get group => integer()();
  IntColumn get user => integer()();

  @override
  Set<Column> get primaryKey => {group, user};
}

// #docregion index
// #docregion mulit-single-col-index
@TableIndex(name: 'user_age', columns: {#age})
@TableIndex(name: 'user_name', columns: {#name})
// #enddocregion mulit-single-col-index
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // #docregion check
  IntColumn get age => integer().check(age.isBiggerThan(Constant(0)))();
  // #enddocregion check
}
// #enddocregion index

// #docregion multi-col-index
@TableIndex(name: 'user_name', columns: {#name, #age})
// #enddocregion multi-col-index

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
