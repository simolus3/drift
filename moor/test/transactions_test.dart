@TestOn('!browser') // todo: Figure out why this doesn't run in js

/*
These tests don't work when compiled to js:

NoSuchMethodError: method not found: 'beginTransaction$0' (executor.beginTransaction$0 is not a function)
package:moor/src/runtime/database.dart 185:45                                 <fn>
org-dartlang-sdk:///sdk/lib/_internal/js_runtime/lib/async_patch.dart 313:19  _wrapJsFunctionForAsync.closure.$protected
org-dartlang-sdk:///sdk/lib/_internal/js_runtime/lib/async_patch.dart 338:23  _wrapJsFunctionForAsync.<fn>
package:stack_trace                                                           StackZoneSpecification._registerBinaryCallback.<fn>
org-dartlang-sdk:///sdk/lib/_internal/js_runtime/lib/async_patch.dart 242:3   Object._asyncStartSync
package:moor/src/runtime/database.dart 185:13                                 QueryEngine.transaction.<fn>
test/data/utils/mocks.dart 22:20                                              MockExecutor.<fn>
package:mockito/src/mock.dart 128:22                                          MockExecutor.noSuchMethod
 */

import 'package:test_api/test_api.dart';
import 'package:moor/moor.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();
    db = TodoDb(executor)..streamQueries = streamQueries;
  });

  test("transactions don't allow creating streams", () {
    expect(() async {
      await db.transaction((t) async {
        t.select(db.users).watch();
      });
    }, throwsStateError);
  });

  test('nested transactions use the outer transaction', () async {
    await db.transaction((t) async {
      await t.transaction((t2) async {
        expect(t2, equals(t));
      });

      // the outer callback has not completed yet, so shouldn't send
      verifyNever(executor.transactions.send());
    });

    verify(executor.transactions.send());
  });

  test('code in callback uses transaction', () async {
    // notice how we call .select on the database, but it should be called on
    // transaction executor.
    await db.transaction((_) async {
      await db.select(db.users).get();
    });

    verifyNever(executor.runSelect(any, any));
    verify(executor.transactions.runSelect(any, any));
  });

  test('transactions rollback after errors', () async {
    final exception = Exception('oh no');
    final future = db.transaction((_) async {
      throw exception;
    });

    await expectLater(future, throwsA(exception));

    verifyNever(executor.transactions.send());
    verify(executor.transactions.rollback());
  });

  test('transactions notify about table udpates after completing', () async {
    when(executor.transactions.runUpdate(any, any))
        .thenAnswer((_) => Future.value(2));

    await db.transaction((t) async {
      await t
          .update(db.users)
          .write(const UsersCompanion(name: Value('Updated name')));

      // Even though we just wrote to users, this only happened inside the
      // transaction, so the top level stream queries should not be updated.
      verifyNever(streamQueries.handleTableUpdates(any));
    });

    // After the transaction completes, the queries should be updated
    verify(streamQueries.handleTableUpdates({db.users})).called(1);
    verify(executor.transactions.send());
  });

  test('the database is opened before starting a transaction', () async {
    await db.transaction((t) async {
      verify(executor.doWhenOpened(any));
    });
  });
}
