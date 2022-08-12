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