import 'dart:async';

import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('calls interceptor methods', () async {
    final interceptor = EmittingInterceptor();
    final events = <String>[];
    interceptor.events.stream.listen(events.add);

    final database = TodoDb(testInMemoryDatabase().interceptWith(interceptor));
    expect(await database.categories.select().get(), isEmpty);
    expect(events, ['select']);

    await database.batch((batch) {
      batch.insert(database.categories,
          CategoriesCompanion.insert(description: 'from batch'));
    });
    expect(events, ['select', 'begin', 'batched', 'commit']);
    events.clear();

    await database.users.insertOne(
        UsersCompanion.insert(name: 'Simon B', profilePicture: Uint8List(0)));
    await database.users.update().write(UsersCompanion(isAwesome: Value(true)));
    await database.users.delete().go();
    expect(events, ['insert', 'update', 'delete']);
  });
}

class EmittingInterceptor extends QueryInterceptor {
  final events = StreamController<String>();

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    events.add('begin');
    return super.beginTransaction(parent);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) {
    events.add('commit');
    return super.commitTransaction(inner);
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) {
    events.add('rollback');
    return super.rollbackTransaction(inner);
  }

  @override
  Future<void> runBatched(
      QueryExecutor executor, BatchedStatements statements) {
    events.add('batched');
    return super.runBatched(executor, statements);
  }

  @override
  Future<void> runCustom(
      QueryExecutor executor, String statement, List<Object?> args) {
    events.add('custom');
    return super.runCustom(executor, statement, args);
  }

  @override
  Future<int> runInsert(
      QueryExecutor executor, String statement, List<Object?> args) {
    events.add('insert');
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runDelete(
      QueryExecutor executor, String statement, List<Object?> args) {
    events.add('delete');
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
      QueryExecutor executor, String statement, List<Object?> args) {
    events.add('update');
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    events.add('select');
    return super.runSelect(executor, statement, args);
  }
}
