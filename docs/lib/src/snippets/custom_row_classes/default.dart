import 'package:drift/drift.dart';

// #docregion start
@UseRowClass(User)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get birthday => dateTime()();
}

class User {
  final int id;
  final String name;
  final DateTime birthday;

  User({required this.id, required this.name, required this.birthday});
}
// #enddocregion start

// #docregion record
@UseRowClass(Record) // Drift will use ({int id, String name})
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
// #enddocregion record

// #docregion record-explicit
typedef TodoItem = ({int id, String content, int author});

@UseRowClass(TodoItem)
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  IntColumn get author => integer().references(Users, #id)();
}

// #enddocregion record-explicit
