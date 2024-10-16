// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:drift_flutter/drift_flutter.dart';

part 'tables.g.dart';

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
  // #docregion withLength
  late final name = text().withLength(min: 1, max: 50)();
  // #enddocregion withLength
  // #docregion named_column
  late final createdAt = boolean().named('created')();
  // #enddocregion named_column
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

// #docregion pk-example
class Items extends Table {
  // #docregion autoIncrement
  late final id = integer().autoIncrement()();
  // #enddocregion autoIncrement
  // More columns...
}
// #enddocregion pk-example

// #docregion custom_table_name
class Products extends Table {
  @override
  String get tableName => 'product_table';
}
// #enddocregion custom_table_name

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
  late final name = text()();
  late final preferences = text().map(TypeConverter.json(
      fromJson: (json) => Preferences.fromJson(json as Map<String, dynamic>),
      toJson: (column) => column.toJson()))();
}
// #enddocregion json_converter

// #docregion custom_json_converter
class PreferencesConverter extends TypeConverter<Preferences, String>
    with JsonTypeConverter2<Preferences, String, Map<String, Object?>> {
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

class ColumnConstraint extends Table {
  // #docregion custom_column_constraint
  late final name =
      integer().nullable().customConstraint('COLLATE BINARY')(); // (1!)
  // #enddocregion custom_column_constraint

  // #docregion custom_column_constraint_not_nullable
  late final username = integer().customConstraint('NOT NULL COLLATE BINARY')();
  // #enddocregion custom_column_constraint_not_nullable
}

// #docregion converter
class DurationConverter extends TypeConverter<Duration /*(1)!*/, int /*(2)!*/ >
    with JsonTypeConverter<Duration, int> /*(3)!*/ {
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

// #docregion custom_pk
class Profiles extends Table {
  late final email = text()();

  @override
  Set<Column<Object>> get primaryKey => {email};
}
// #enddocregion custom_pk

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

// #docregion enum
enum Category { school, work, home }

class PhoneNumbers extends Table {
  late final category = intEnum<Category>()();
  late final number = text()();
  //...
}
// #enddocregion enum

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

void _query4() async {
  final db = CatDatabase(driftDatabase(name: "categories"));
  // #docregion use_converter
  await db.managers.employees.createReturning(
    (create) => create(vacationTimeRemaining: const Duration(days: 10)),
  );

  // #enddocregion use_converter
}

@DriftDatabase(tables: [Reservations, Employees])
class CatDatabase extends _$CatDatabase {
  CatDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

// #docregion index
@TableIndex(name: "patients_age", columns: {#age})
@TableIndex(name: "patients_name", columns: {#name})
class Patients extends Table {
  late final name = text()();
  late final age = integer()();
}
// #enddocregion index

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
