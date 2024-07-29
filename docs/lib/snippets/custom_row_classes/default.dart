import 'package:drift/drift.dart';

part 'default.g.dart';

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

// #docregion ignored
@UseRowClass(Group)
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Group {
  final int id;
  final String name;

  // This class will ignore the createdAt column from the database
  // final DateTime createdAt;

  /// Both of these fields are optional, so they can be added to the class
  final int userCount;
  final List<User>? users;

  Group({required this.id, required this.name, this.userCount = 0, this.users});
}
// #enddocregion ignored

// #docregion async
@UseRowClass(Book, constructor: "fetchUrl")
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
}

class Book {
  final int id;
  final String title;
  final String url;

  Book({required this.id, required this.title, required this.url});

  static Future<Book> fetchUrl({required int id, required String title}) async {
    final url = await _fetchUrlForTitle(title);
    return Book(id: id, title: title, url: url);
  }
}
// #enddocregion async

Future<String> _fetchUrlForTitle(String title) async {
  return 'https://example.com/books/$title';
}

@DriftDatabase(
  tables: [Users, Groups, Books],
)
// ignore: unused_element
class _MyDatabase extends _$_MyDatabase {
  _MyDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
