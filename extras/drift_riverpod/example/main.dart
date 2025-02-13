import 'package:drift_riverpod/drift_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
Future<String> version(Ref _) async => '3.0.0';

@riverpod
Stream<String> hiThere(Ref ref, String user, {String? another}) async* {
  yield 'Hi';
  yield user;
}

final database = StateProvider((ref) {
  return Database(NativeDatabase.memory());
});

@queryProvider
final countUsers = database.magicQuery('SELECT COUNT(*), 1 FROM users;');

// better? no sql injection, query is rewritten by drift
@queryProvider
final userById2 =
    database.users2((int id) => 'SELECT * FROM users WHERE id = $id;');

void main() {}

class Users extends Table {
  IntColumn get id => integer()();
}

@DriftDatabase(tables: [Users])
class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}
