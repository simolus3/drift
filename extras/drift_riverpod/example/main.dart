import 'package:drift_riverpod/drift_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:riverpod/riverpod.dart';

part 'main.g.dart';

final database = DriftProvider((ref) => Database(NativeDatabase.memory()));

@QueryProvider(singleRow: true)
final countUsers = database.magicQuery('SELECT COUNT(*) FROM users;');

@queryProvider
final userById =
    database.users2((int id) => 'SELECT * FROM users WHERE id = $id;');

void main() async {
  final container = ProviderContainer();

  container.listen(userById(1), (prev, state) {
    print('State for userById(1): $state');
  });

  container.listen(countUsers, (prev, state) {
    print('State for countUsers: $state');
  });
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(tables: [Users])
class Database extends _$Database {
  Database(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) async {
        await m.createAll();
        await into(users).insert(UsersCompanion.insert());
      });

  @override
  int get schemaVersion => 1;
}
