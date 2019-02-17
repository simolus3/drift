import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('streams fetch when the first listener attaches', () {
    final stream = db.select(db.users).watch();

    verifyNever(executor.runSelect(any, any));

    stream.listen((_) {});

    verify(executor.runSelect(any, any)).called(1);
  });

  test('streams fetch when the underlying data changes', () {
    db.select(db.users).watch().listen((_) {});

    db.markTableUpdated('users');

    // twice: Once because the listener attached, once because the data changed
    verify(executor.runSelect(any, any)).called(2);
  });

  group("streams don't fetch", () {
    test('when no listeners were attached', () {
      db.select(db.users).watch();

      db.markTableUpdated('users');

      verifyNever(executor.runSelect(any, any));
    });

    test('when the data updates after the listener has detached', () {
      final subscription = db.select(db.users).watch().listen((_) {});
      clearInteractions(executor);

      subscription.cancel();
      db.markTableUpdated('users');

      verifyNever(executor.runSelect(any, any));
    });
  });
}
