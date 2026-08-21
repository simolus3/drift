import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:drift_manager/drift_manager.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

part 'database.g.dart';

class TableWithEveryColumnType extends Table {
  IntColumn get id => integer().autoIncrement();
  BoolColumn get aBool => boolean().nullable();
  DateTimeColumn get aDateTime => dateTime().nullable();
  TextColumn get aText => text().nullable();
  IntColumn get anInt => integer().nullable();
  Int64Column get anInt64 => int64().nullable();
  RealColumn get aReal => real().nullable();
  BlobColumn get aBlob => blob().nullable();
  IntColumn get anIntEnum => intEnum<TodoStatus>().nullable();
  TextColumn get aTextWithConverter => text()
      .named('insert')
      .map(const CustomJsonConverter())
      .nullable()
      .nullable();
}

enum TodoStatus { open, workInProgress, done }

class Users extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text().withLength(min: 6, max: 32).unique();
  BoolColumn get isAwesome => boolean().withDefault(const Literal(true));

  BlobColumn get profilePicture => blob();
  DateTimeColumn get creationTime => dateTime()
      // ignore: recursive_getters
      .check(creationTime.isGreaterThan(Literal(DateTime.utc(1950))))
      .withDefault(currentDateAndTime);
}

class MyCustomObject {
  final String data;

  MyCustomObject(this.data);

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MyCustomObject && other.data == data;
  }
}

class CustomConverter extends TypeConverter<MyCustomObject, String> {
  const CustomConverter();

  @override
  MyCustomObject fromSql(String fromDb) {
    return MyCustomObject(fromDb);
  }

  @override
  String toSql(MyCustomObject value) {
    return value.data;
  }
}

class CustomJsonConverter extends CustomConverter
    with JsonTypeConverter2<MyCustomObject, String, Map<String, Object?>> {
  const CustomJsonConverter();

  @override
  MyCustomObject fromJson(Map<String, Object?> json) {
    return MyCustomObject(json['data'] as String);
  }

  @override
  Map<String, Object?> toJson(MyCustomObject value) {
    return {'data': value.data};
  }
}

@DataClassName('TodoEntry')
class TodosTable extends Table {
  @override
  String get tableName => 'todos';

  IntColumn get id => integer().autoIncrement();
  TextColumn get title => text().withLength(min: 4, max: 16).nullable();
  TextColumn get content => text();
  DateTimeColumn get targetDate => dateTime().nullable().unique();
  @ReferenceName("todos")
  IntColumn get category =>
      integer().references(Categories, #id, initiallyDeferred: true).nullable();

  TextColumn get status => textEnum<TodoStatus>().nullable();

  @override
  List<Set<Column>>? get uniqueKeys => [
    {title, category},
    {title, targetDate},
  ];
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get description =>
      text().named('desc').customConstraint('NOT NULL UNIQUE');
  IntColumn get priority =>
      intEnum<CategoryPriority>().withDefault(const Literal(0));

  TextColumn get descriptionInUpperCase =>
      text().generatedAs(description.upper());
}

enum CategoryPriority { low, medium, high }

class Department extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text().nullable();
}

class Product extends Table {
  TextColumn get sku => text();
  TextColumn get name => text().nullable();
  IntColumn get department => integer().references(Department, #id).nullable();
}

class Listing extends Table {
  IntColumn get id => integer().autoIncrement();
  @ReferenceName('listings')
  TextColumn get product => text().references(Product, #sku);
  @ReferenceName('listings')
  IntColumn get store => integer().references(Store, #id).nullable();
  RealColumn get price => real().nullable();
}

class Store extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text().nullable();
}

@DriftDatabase(
  tables: [
    Categories,
    TableWithEveryColumnType,
    TodosTable,
    Users,
    Department,
    Product,
    Listing,
    Store,
  ],
)
final class TestDatabase extends _$TestDatabase {
  TestDatabase(super.implementation);

  factory TestDatabase.inMemory() {
    return TestDatabase(
      DriftConnection(
        dialect: SqliteDialect.new,
        openConnection: () async {
          return SqliteConnection(sqlite3.openInMemory());
        },
      ),
    );
  }

  @override
  int get schemaVersion => 1;
}
