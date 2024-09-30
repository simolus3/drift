// ignore_for_file: unused_local_variable, unused_element

// #docregion superhero_schema
import 'package:drift/drift.dart';
// #enddocregion superhero_schema

import 'package:drift_flutter/drift_flutter.dart';

// #docregion superhero_schema

part 'schema.g.dart';

// #enddocregion superhero_schema

// #docregion superhero_schema
// #docregion superhero_dataclass
class Superheros extends Table {
  // #docregion superhero_columns
  // #docregion pk
  late final id = integer().autoIncrement()();
  // #enddocregion pk
  // #docregion unique_columns
  late final name = text().unique()();
  // #enddocregion unique_columns
  late final secretName = text().nullable()();
  // #docregion optional_columns
  late final age = integer().nullable()();
  // #enddocregion optional_columns
  late final height = text().nullable()();
  // #enddocregion superhero_columns
}

// #enddocregion superhero_dataclass
// #enddocregion superhero_schema
// #docregion superhero_database
@DriftDatabase(tables: [Superheros]) // 👈👈👈
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
// #enddocregion superhero_database

void _query() async {
  // #docregion superhero_query
  // Initialize the database
  final db = AppDatabase(driftDatabase(name: "superheroes"));

  // Create a new superhero
  db.managers.superheros.create(
    (create) => create(
        name: "Ironman", secretName: Value("Tony Stark"), height: Value("6'1")),
  );

  // Query all superheros
  final superheros = await db.managers.superheros.get();

  // Print the superheros
  for (var hero in superheros) {
    print("Superhero: ${hero.name} - Secret Name: ${hero.secretName}");
  }

  // #enddocregion superhero_query
  // #docregion optional_usage
  db.managers.superheros.create(
    (create) => create(
      name: "Ironman",
      secretName: Value("Tony Stark"), // 👈👈👈
      age: Value(null), // 👈👈👈
    ),
  );
  // #enddocregion optional_usage
}

// #docregion custom_pk
class TableWithTextPrimaryKey extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
// #enddocregion custom_pk

// #docregion composite_pk
class Students extends Table {
  late final parentPhone = text()();
  late final firstName = text()();
  late final lastName = text()();

  @override
  Set<Column<Object>> get primaryKey => {parentPhone, firstName};
}
// #enddocregion composite_pk

// #docregion base_pk_class
// Define this mixin once
mixin PkMixin on Table {
  late final id = integer().autoIncrement()();
}

/// And reuse it in other tables
class SomeOtherTable extends Table with PkMixin {
  //...
}

class AndAnotherTable extends Table with PkMixin {
  //...
}
// #enddocregion base_pk_class

// #docregion columns
class Doctors extends Table {
  late final id = text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
// #enddocregion columns

// #docregion bad_name
@DataClassName('Category')
class Categories extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
}
// #enddocregion bad_name

void _query1() async {
  final db = AppDatabase(driftDatabase(name: "superheroes"));
  // #docregion superhero_dataclass
  Superhero batman = await db.managers.superheros
      .filter((s) => s.name.equals("Batman"))
      .getSingle();
  // #enddocregion superhero_dataclass
}

@DriftDatabase(tables: [Categories, Reservations, Employees, PhoneNumbers])
class CatDatabase extends _$CatDatabase {
  CatDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void _query2() async {
  final db = CatDatabase(driftDatabase(name: "categories"));
  // #docregion bad_name
  List<Category> categories = await db.managers.categories.get();
  // #enddocregion bad_name
}

// #docregion custom_table_name
class TodoItems extends Table {
  //...

  @override
  String get tableName => 'todoItems';
}

// #enddocregion custom_table_name
// #docregion datetime
class Reservations extends Table {
  late final id = integer().autoIncrement()();
  late final time = dateTime()();
  // More columns...
}

// #enddocregion datetime
void _query3() async {
  final db = CatDatabase(driftDatabase(name: "categories"));
  // #docregion datetime
  await db.managers.reservations.create(
    (create) => create(time: DateTime(2021, 1, 1, 12, 0)),
  );
  // #enddocregion datetime
}

// #docregion converter
/// Converter for [Duration] to [int] and vice versa
class DurationConverter
    extends TypeConverter<Duration /*(1)!*/, int /*(2)!*/ > {
  const DurationConverter();

  @override
  int toSql(Duration value) {
    return value.inMicroseconds;
  }

  @override
  Duration fromSql(int fromDb) {
    return Duration(microseconds: fromDb);
  }
}
// #enddocregion converter

// #docregion apply_converter
class Employees extends Table {
  late final vacationTimeRemaining = integer().map(const DurationConverter())();
}

// #enddocregion apply_converter

void _query4() async {
  final db = CatDatabase(driftDatabase(name: "categories"));
  // #docregion use_converter
  db.managers.employees.create(
    (create) => create(vacationTimeRemaining: const Duration(days: 10)),
  );
  // #enddocregion use_converter
}

// #docregion enum
enum Category { school, work, home }

class PhoneNumbers extends Table {
  late final category = intEnum<Category>()();
  late final number = text()();
  //...
}
// #enddocregion enum

void _query5() async {
  final db = CatDatabase(driftDatabase(name: "categories"));
  // #docregion enum
  await db.managers.phoneNumbers.create(
      (create) => create(category: Category.school, number: "123-456-7890"));
  // #enddocregion enum
}

class Users extends Table {
  // #docregion client_default
  late final isAdmin = boolean().clientDefault(() => false)();
  // #enddocregion client_default
}

class Users2 extends Table {
  // #docregion db_default
  late final isAdmin = boolean().withDefault(Constant(false))();
  // #enddocregion db_default
  // #docregion named_column
  late final createdAt = boolean().named('created')();
  // #enddocregion named_column
  // #docregion json_key
  @JsonKey('parent')
  late final parentCategory = integer()();
  // #enddocregion json_key
}

class User {
  final int id;
  final String name;
  final bool isAdmin;
  // #docregion dart_default
  User({
    required this.id,
    required this.name,
    this.isAdmin = false, // 👈👈👈
  });
  // #enddocregion dart_default
}

// #docregion unique-table
class DinnerReservations extends Table {
  @override
  List<Set<Column>> get uniqueKeys => [
        {table, time}
      ];

  late final table = text()();
  late final time = dateTime()();
}
// #enddocregion unique-table

class ColumnConstraint extends Table {
  // #docregion custom_column_constraint
  late final name =
      integer().nullable().customConstraint('COLLATE BINARY')(); // (1!)
  // #enddocregion custom_column_constraint

  // #docregion custom_column_constraint_not_nullable
  late final username = integer().customConstraint('NOT NULL COLLATE BINARY')();
  // #enddocregion custom_column_constraint_not_nullable
}

// #docregion custom-constraint-table
class TableWithCustomConstraints extends Table {
  late final foo = integer()();
  late final bar = integer()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (foo, bar) REFERENCES group_memberships ("group", user)',
      ];
}
// #enddocregion custom-constraint-table

class GroupMemberships extends Table with PkMixin {
  late final group = integer()();
  late final user = integer()();
}

// #docregion custom-check
class Student extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
  late final IntColumn age =
      integer().nullable().check(age.isBiggerOrEqualValue(0))();
}
// #enddocregion custom-check
