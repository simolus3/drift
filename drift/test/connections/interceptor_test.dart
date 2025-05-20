import 'dart:async';
import 'dart:typed_data';

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
    await database.initialize();
    events.clear();

    expect(await database.select(database.categories).get(), isEmpty);
    expect(events, ['read']);

    await database.batch((batch) {
      batch.insert(database.categories,
          CategoriesCompanion.insert(description: 'from batch'));
    });
    expect(events, ['read', 'begin', 'batched', 'commit']);
    events.clear();

    await database.into(database.users).insert(
        UsersCompanion.insert(name: 'Simon B', profilePicture: Uint8List(0)));
    await database
        .update(database.users)
        .write(UsersCompanion(isAwesome: Value(true)));
    await database.delete(database.users).go();

    expect(events, ['write: insert', 'write: update', 'write: delete']);
  });

  test('calls interceptor methods in runWithInterceptor', () async {
    final interceptor = EmittingInterceptor();
    final events = <String>[];
    interceptor.events.stream.listen(events.add);

    final database = TodoDb(testInMemoryDatabase());
    expect(await database.select(database.categories).get(), isEmpty);

    await database.runWithInterceptor(
      () => database.batch((batch) {
        batch.insert(database.categories,
            CategoriesCompanion.insert(description: 'from batch'));
      }),
      interceptor: interceptor,
    );
    expect(events, ['begin', 'batched', 'commit']);
    events.clear();

    await database.into(database.users).insert(
        UsersCompanion.insert(name: 'Simon B', profilePicture: Uint8List(0)));
    await database.runWithInterceptor(
        () => database
            .update(database.users)
            .write(UsersCompanion(isAwesome: Value(true))),
        interceptor: interceptor);
    await database.delete(database.users).go();

    expect(events, ['write: update']);
  });
}

final class EmittingInterceptor extends QueryInterceptor {
  final events = StreamController<String>();

  @override
  Future<DriftSession> begin(
      DriftTransactionParent parent, TransactionOptions options) {
    events.add('begin');
    return super.begin(parent, options);
  }

  @override
  Future<void> commit(DriftTransactionSession transaction) {
    events.add('commit');
    return super.commit(transaction);
  }

  @override
  Future<void> rollback(DriftTransactionSession transaction) {
    events.add('rollback');
    return super.rollback(transaction);
  }

  @override
  Future<QueryResult> execute(DriftSession session, StatementInfo statement) {
    if (statement.isReadOnly) {
      events.add('read');
    } else {
      final writes =
          statement.expectedWrites.map((e) => e.kind?.name).join(', ');
      events.add('write: $writes');
    }

    return super.execute(session, statement);
  }

  @override
  Future<List<QueryResult>> executeBatch(
      DriftSession session, StatementBatch batch) {
    events.add('batched');
    return super.executeBatch(session, batch);
  }
}
