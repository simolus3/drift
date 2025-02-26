import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_riverpod/drift_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

part 'provider_test.g.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('closes database when container is disposed', () async {
    final database = container.read(_database);
    await database.customSelect('SELECT 1').get();

    container.dispose();
    await pumpEventQueue();

    expect(() => database.customSelect('SELECT 1').get(), throwsStateError);
  });

  test('can run simple queries', () async {
    final values = StreamQueue(container.asStream(allUsers));

    await expectLater(values, emits(isAsyncLoading()));
    await expectLater(values, emits(isAsyncData(hasLength(2))));

    await container.read(_database).users.deleteAll();
    await expectLater(values, emits(isAsyncData(isEmpty)));
  });

  test('can bind constants', () async {
    final values = StreamQueue(container.asStream(userByConstant));

    await expectLater(values, emits(isAsyncLoading()));
    await expectLater(
        values, emits(isAsyncData(User(id: 1, name: 'First user'))));
  });

  test('can bind parameters', () async {
    final values = StreamQueue(container.asStream(userById(2)));

    await expectLater(values, emits(isAsyncLoading()));
    await expectLater(
        values, emits(isAsyncData(User(id: 2, name: 'Second user'))));
  });
}

final _database = DriftProvider((ref) {
  return TestDatabase(NativeDatabase.memory());
});

@queryProvider
final allUsers = _database.$allUsers('SELECT * FROM users;');

const firstId = 1;

@QueryProvider(singleRow: true)
final userByConstant =
    _database.$constantUser('SELECT * FROM users WHERE id = $firstId');

@QueryProvider(singleRow: true)
final userById =
    _database.$userById((int id) => 'SELECT * FROM users WHERE id = $id');

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [Users])
class TestDatabase extends _$TestDatabase {
  TestDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) async {
        await m.createAll();

        await into(users).insert(UsersCompanion.insert(name: 'First user'));
        await into(users).insert(UsersCompanion.insert(name: 'Second user'));
      });

  @override
  int get schemaVersion => 1;
}

extension on ProviderContainer {
  Stream<T> asStream<T>(ProviderListenable<T> provider) {
    return Stream.multi((controller) {
      final subscription = listen(
        provider,
        (prev, now) => controller.addSync(now),
        onError: controller.addError,
        fireImmediately: true,
      );

      controller.onCancel = subscription.close;
    }, isBroadcast: true);
  }
}

Matcher isAsyncLoading() {
  return isA<AsyncLoading>();
}

Matcher isAsyncData(Object? data) {
  return isA<AsyncData>().having((e) => e.value, 'value', data);
}
