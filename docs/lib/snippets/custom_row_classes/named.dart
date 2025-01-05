import 'package:drift/drift.dart';

// #docregion named
@UseRowClass(User, constructor: 'fromDb')
class Users extends Table {
  // ...
  // #enddocregion named
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get birthday => dateTime()();
  // #docregion named
}

class User {
  final int id;
  final String name;
  final DateTime birthday;

  User.fromDb({required this.id, required this.name, required this.birthday});
}
// #enddocregion named
