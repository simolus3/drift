import 'package:drift3_preview/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockSession session;

  setUp(() async {
    session = MockSession();
    db = TodoDb(createConnection(session));

    // Don't collect CREATE TABLE statements in mock to make debugging easier.
    await db.initialize();
    clearInteractions(session);
  });

  const columns = '"id","name","is_awesome","profile_picture","creation_time"';

  test('when nullsOrder is null it ignored', () async {
    final query = db.select(db.users);
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    await query.get();
    verify(
      session.executeSql('SELECT $columns FROM "users" ORDER BY "name" ASC;'),
    );
  });

  test('nullsOrder is last', () async {
    final query = db.select(db.users);
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.name, nulls: NullsOrder.last),
    ]);
    await query.get();
    verify(
      session.executeSql(
        'SELECT $columns FROM "users" ORDER BY "name" ASC NULLS LAST;',
      ),
    );
  });

  test('nullsOrder is first', () async {
    final query = db.select(db.users);
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.name, nulls: NullsOrder.first),
    ]);
    await query.get();
    verify(
      session.executeSql(
        'SELECT $columns FROM "users" ORDER BY "name" ASC NULLS FIRST;',
      ),
    );
  });

  test('complex order by with different nullsOrder', () async {
    final query = db.select(db.users);
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.name, nulls: NullsOrder.first),
      (tbl) => OrderingTerm(expression: tbl.creationTime),
      (tbl) =>
          OrderingTerm(expression: tbl.profilePicture, nulls: NullsOrder.last),
    ]);
    await query.get();
    verify(
      session.executeSql(
        'SELECT $columns FROM "users" ORDER BY "name" ASC NULLS FIRST,"creation_time" ASC,"profile_picture" ASC NULLS LAST;',
      ),
    );
  });

  test('works with helper factories', () {
    final table = db.users;

    expect(OrderingTerm.asc(table.id), generates('"id" ASC'));
    expect(
      OrderingTerm.asc(table.id, nulls: NullsOrder.last),
      generates('"id" ASC NULLS LAST'),
    );
    expect(
      OrderingTerm.desc(table.id, nulls: NullsOrder.first),
      generates('"id" DESC NULLS FIRST'),
    );
  });
}
