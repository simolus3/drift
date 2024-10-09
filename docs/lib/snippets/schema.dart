// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:drift_flutter/drift_flutter.dart';

part 'schema.g.dart';

// #docregion simple_schema
class Persons extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()(); // (1)!
  late final age = integer().nullable()(); // (2)!
}
// #enddocregion simple_schema

// #docregion simple_schema_db
@DriftDatabase(tables: [Persons])
class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}
// #enddocregion simple_schema_db

// #docregion schema
class Musicians extends Table {
  late final id = integer().autoIncrement()();
  late final firstName = text()();
  late final lastName = text()();
  late final instrument = text()();
}

class Albums extends Table {
  late final id = integer().autoIncrement()();
  late final title = text()();
  late final releaseDate = dateTime()();
  late final numStars = integer()();
  late final artist = integer().references(Musicians, #id)();
}
// #enddocregion schema

bool isInDarkMode() => false;

class Table1 extends Table {
  // #docregion client_default
  late final useDarkMode = boolean().clientDefault(() => false)();
  // #enddocregion client_default
  // #docregion db_default
  late final isAdmin = boolean().withDefault(Constant(false))();
  // #enddocregion db_default
  // #docregion optional_columns
  late final age = integer().nullable()();
  // #enddocregion optional_columns
  // #docregion unique_columns
  late final username = text().unique()();
  // #enddocregion unique_columns
}

class Table2 extends Table {
  // #docregion check_column
  late final Column<int> age = integer().check(age.isBiggerOrEqualValue(0))();
  // #enddocregion check_column
}

// #docregion generated_column
class Squares extends Table {
  late final length = integer()();
  late final width = integer()();
  late final area = integer().generatedAs(length * width)();
}
// #enddocregion generated_column

// #docregion generated_column_stored
class Boxes extends Table {
  late final length = integer()();
  late final width = integer()();
  late final area = integer().generatedAs(length * width, stored: true)();
}
// #enddocregion generated_column_stored

// #docregion superhero_dataclass
class Superheros extends Table {
  // #docregion superhero_columns
  // #docregion pk
  late final id = integer().autoIncrement()();
  // #enddocregion pk
  late final secretName = text().nullable()();
  late final age = integer().nullable()();
  late final height = text().nullable()();
  // #enddocregion superhero_columns
}

// #enddocregion superhero_dataclass
// #docregion superhero_database
@DriftDatabase(tables: [Superheros])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

// #enddocregion superhero_database

// #docregion custom_pk
class Profiles extends Table {
  late final email = text()();

  @override
  Set<Column<Object>> get primaryKey => {email};
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
  late final name = text()();
}
// #enddocregion bad_name

void _query1() async {
  final db = AppDatabase(driftDatabase(name: "superheroes"));
  // #docregion superhero_dataclass
  Superhero batman = await db.managers.superheros.getSingle();
  // #enddocregion superhero_dataclass
}

@DriftDatabase(tables: [Reservations, Employees, PhoneNumbers])
class CatDatabase extends _$CatDatabase {
  CatDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

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

class Users2 extends Table {
  late final isAdmin = boolean().withDefault(Constant(false))();
  // #docregion named_column
  late final createdAt = boolean().named('created')();
  // #enddocregion named_column
  // #docregion json_key
  @JsonKey('parent')
  late final parentCategory = integer()();
  // #enddocregion json_key
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
  late final Column<int> age = integer().check(age.isBiggerOrEqualValue(0))();
}
// #enddocregion custom-check

// #docregion pk-example
class Items extends Table {
  late final id = integer().autoIncrement()();
  // More columns...
}
// #enddocregion pk-example

// #docregion custom_table_name
class Products extends Table {
  @JsonKey('product_name')
  late final name = text().named('product_name')();

  @override
  String get tableName => 'product_table';
}
// #enddocregion custom_table_name

// #docregion table_mixin
mixin TableMixin on Table {
  // Primary key column
  late final id = integer().autoIncrement()();

  // Column for created at timestamp
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
}

class Posts extends Table with TableMixin {
  late final content = text()();
}
// #enddocregion table_mixin

// #docregion jsonserializable_type
class Preferences {
  final bool isDarkMode;
  final String language;

  Preferences({required this.isDarkMode, required this.language});

  // JSON Serialization
  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      isDarkMode: json['isDarkMode'] as bool,
      language: json['language'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'language': language,
      };

  // Equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Preferences &&
          runtimeType == other.runtimeType &&
          isDarkMode == other.isDarkMode &&
          language == other.language;

  @override
  int get hashCode => isDarkMode.hashCode ^ language.hashCode;
}
// #enddocregion jsonserializable_type

// #docregion json_converter
class Accounts extends Table {
  late final preferences = text().map(TypeConverter.json(
      fromJson: (json) => Preferences.fromJson(json as Map<String, dynamic>),
      toJson: (column) => column.toJson()))();
}
// #enddocregion json_converter

// #docregion custom_json_converter
class PreferencesConverter extends TypeConverter<Preferences, String>
    with
        JsonTypeConverter2<Preferences, String /*(1)!*/,
            Map<String, Object?> /*(2)!*/ > {
  @override
  Preferences fromJson(Map<String, Object?> json) {
    return Preferences.fromJson(json);
  }

  @override
  Preferences fromSql(String fromDb) {
    return Preferences.fromJson(jsonDecode(fromDb) as Map<String, dynamic>);
  }

  @override
  Map<String, Object?> toJson(Preferences value) {
    return value.toJson();
  }

  @override
  String toSql(Preferences value) {
    return jsonEncode(value.toJson());
  }
}
// #enddocregion custom_json_converter
