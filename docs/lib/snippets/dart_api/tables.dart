// ignore_for_file: invalid_annotation_target, recursive_getters, unused_element

import 'package:drift/drift.dart';
import 'package:drift_docs/snippets/_shared/todo_tables.drift.dart';
import 'package:uuid/uuid.dart';

// #docregion nnbd
class Items extends Table {
  IntColumn get category => integer().nullable()();
  // ...
}
// #enddocregion nnbd

// #docregion custom-column-name

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

// #docregion column-name
class Author extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().named('author_name')();
}

// #enddocregion column-name
// #docregion generated-column
@TableIndex(name: 'order_index', columns: {#total})
class Order extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 25.35
  RealColumn get price => real()();
  // 2
  IntColumn get quantity => integer()();
  // 50.70
  RealColumn get total =>
      real().generatedAs(price * quantity.cast(DriftSqlType.double))();
}
// #enddocregion generated-column

// #docregion reference-name
class Book extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get name => integer().references(Books, #id)();
  @ReferenceName("books")
  IntColumn get publisher => integer().references(Publisher, #id)();
}

class Publisher extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get name =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
}
// #enddocregion reference-name

// #docregion custom-data-class-name
@DataClassName('EnabledCategory')
// #docregion custom-table-name
// #docregion custom-column-name
// #docregion custom-json-key
class EnabledCategories extends Table {
  // #enddocregion custom-json-key
  // #enddocregion custom-data-class-name
  // #enddocregion custom-column-name
  @override
  String get tableName => 'categories';
  // #enddocregion custom-table-name
// #docregion custom-json-key

  @JsonKey('parent_id')
// #docregion custom-column-name
  IntColumn get parentCategory => integer().named('parent')();
// #docregion custom-data-class-name
  //...
// #docregion custom-table-name
}
// #enddocregion custom-table-name
// #enddocregion custom-json-key
// #enddocregion custom-data-class-name
// #enddocregion custom-column-name

// #docregion extention-on-data-class
extension on User {
  String get fullName => '$firstName $lastName';
}

// #enddocregion extention-on-data-class
// #docregion custom-col-constraint
class Groups extends Table {
  IntColumn get name =>
      integer().nullable().customConstraint('COLLATE BINARY')();
}
// #enddocregion custom-col-constraint
