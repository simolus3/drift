import 'package:drift/drift.dart' hide isNull;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('when nullsOrder is null it ignored', () async {
    final query = db.select(db.users);
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    await query.get();
    verify(executor.runSelect(
      'SELECT * FROM users ORDER BY name ASC;',
      argThat(isEmpty),
    ));
  });

  test('nullsOrder is last', () async {
    final query = db.select(db.users);
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.name,
            nulls: NullsOrder.last,
          ),
    ]);
    await query.get();
    verify(executor.runSelect(
      'SELECT * FROM users ORDER BY name ASC NULLS LAST;',
      argThat(isEmpty),
    ));
  });

  test('nullsOrder is first', () async {
    final query = db.select(db.users);
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.name,
            nulls: NullsOrder.first,
          ),
    ]);
    await query.get();
    verify(executor.runSelect(
      'SELECT * FROM users ORDER BY name ASC NULLS FIRST;',
      argThat(isEmpty),
    ));
  });

  test('complex order by with different nullsOrder', () async {
    final query = db.select(db.users);
    query.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.name,
            nulls: NullsOrder.first,
          ),
      (tbl) => OrderingTerm(
            expression: tbl.creationTime,
          ),
      (tbl) => OrderingTerm(
            expression: tbl.profilePicture,
            nulls: NullsOrder.last,
          ),
    ]);
    await query.get();
    verify(executor.runSelect(
      'SELECT * FROM users ORDER BY name ASC NULLS FIRST, creation_time ASC, profile_picture ASC NULLS LAST;',
      argThat(isEmpty),
    ));
  });
}
