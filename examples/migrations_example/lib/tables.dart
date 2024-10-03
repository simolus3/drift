import 'package:drift/drift.dart';

// This index on the user table has been added in schema version 10
@TableIndex(name: 'user_name', columns: {#name})
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  // added in schema version 2, got a default in version 4
  TextColumn get name => text().withDefault(const Constant('name'))();

  // Column added in version 6, check added in version 11
  DateTimeColumn get birthday => dateTime()
      .nullable()
      // ignore: recursive_getters
      .check(birthday.isBiggerThan(Constant(DateTime(1900))))();

  IntColumn get nextUser => integer().nullable().references(Users, #id)();

  // This unique constraint was added in schema version 8
  @override
  List<Set<Column>> get uniqueKeys => [
        {name, birthday}
      ];

  @override
  List<String> get customConstraints => [
        // This constraint has been added in schema version 9
        'CHECK (LENGTH(name) < 10)',
      ];
}
