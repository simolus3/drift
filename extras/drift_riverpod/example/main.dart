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

final Provider<AsyncValue<int>> users =
    database.magicQuery('SELECT COUNT(*) FROM users;');

// meh
final userById = database.users('SELECT * FROM user WHERE id = ?;');

// better? no sql injection, query is rewritten by drift
final userById2 =
    database.users2((int id) => 'SELECT * FROM user WHERE id = $id;');

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

// This is what we should generate
extension on ProviderListenable<Database> {
  Provider<AsyncValue<int>> magicQuery(String sql) {
    throw 'unsupported';
  }

  ProviderFamily<AsyncValue<User>, int> users(String sql) {
    throw 'unsupported';
  }

  ProviderFamily<AsyncValue<User>, ({int id})> users2(
      String Function(int id) sql) {
    throw 'unsupported';
  }
}
