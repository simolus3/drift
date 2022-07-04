import 'package:drift/drift.dart' hide isNull;
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;

  setUp(() async {
    db = TodoDb.connect(testInMemoryDatabase());

    // we selectOnly from users for the lack of a better option. Insert one
    // row so that getSingle works
    await db.into(db.users).insert(
        UsersCompanion.insert(name: 'User name', profilePicture: Uint8List(0)));
  });

  tearDown(() => db.close());

  Future<T> eval<T>(Expression<T> expr, {TableInfo? onTable}) {
    final query = db.selectOnly(onTable ?? db.users)..addColumns([expr]);
    return query.getSingle().then((row) => row.read(expr));
  }

  test('plus and minus on DateTimes', () async {
    const nowExpr = currentDateAndTime;
    final tomorrow = nowExpr + const Duration(days: 1);
    final nowStamp = nowExpr.secondsSinceEpoch;
    final tomorrowStamp = tomorrow.secondsSinceEpoch;

    final row = await (db.selectOnly(db.users)
          ..addColumns([nowStamp, tomorrowStamp]))
        .getSingle();

    expect(row.read(tomorrowStamp) - row.read(nowStamp),
        const Duration(days: 1).inSeconds);
  });

  test('extracting values from datetime', () {
    final expr = Variable.withDateTime(DateTime.utc(2020, 09, 04, 8, 55));

    expect(eval(expr.year), completion(2020));
    expect(eval(expr.month), completion(9));
    expect(eval(expr.day), completion(4));
    expect(eval(expr.hour), completion(8));
    expect(eval(expr.minute), completion(55));
    expect(eval(expr.second), completion(0));

    expect(eval(expr.date), completion('2020-09-04'));
    expect(eval(expr.time), completion('08:55:00'));
    expect(eval(expr.datetime), completion('2020-09-04 08:55:00'));
  });

  test('rowid', () {
    expect(eval(db.users.rowId), completion(1));
  });

  test('aggregate expressions for datetimes', () async {
    final firstTime = DateTime(2021, 5, 7);
    final secondTime = DateTime(2021, 5, 14);

    await db.delete(db.users).go();
    await db.into(db.users).insert(
          UsersCompanion.insert(
              name: 'User name',
              profilePicture: Uint8List(0),
              creationTime: Value(firstTime)),
        );
    await db.into(db.users).insert(
          UsersCompanion.insert(
              name: 'User name 2',
              profilePicture: Uint8List(0),
              creationTime: Value(secondTime)),
        );

    expect(eval(db.users.creationTime.min()), completion(firstTime));
    expect(eval(db.users.creationTime.max()), completion(secondTime));
    expect(eval(db.users.creationTime.avg()),
        completion(DateTime(2021, 5, 10, 12)));
  });

  group('aggregatte', () {
    setUp(() => db.delete(db.users).go());

    group('groupConcat', () {
      setUp(() async {
        for (var i = 0; i < 5; i++) {
          await db.into(db.users).insert(UsersCompanion.insert(
              name: 'User $i', profilePicture: Uint8List(0)));
        }
      });

      test('simple', () {
        expect(eval(db.users.id.groupConcat()), completion('2,3,4,5,6'));
      });

      test('custom separator', () {
        expect(eval(db.users.id.groupConcat(separator: '-')),
            completion('2-3-4-5-6'));
      });

      test('distinct', () async {
        for (var i = 0; i < 5; i++) {
          await db
              .into(db.todosTable)
              .insert(TodosTableCompanion.insert(content: 'entry $i'));
          await db
              .into(db.todosTable)
              .insert(TodosTableCompanion.insert(content: 'entry $i'));
        }

        expect(
            eval(db.todosTable.content.groupConcat(distinct: true),
                onTable: db.todosTable),
            completion('entry 0,entry 1,entry 2,entry 3,entry 4'));
      });

      test('filter', () {
        expect(
            eval(db.users.id
                .groupConcat(filter: db.users.id.isBiggerThanValue(3))),
            completion('4,5,6'));
      });
    });

    test('filters', () async {
      await db.into(db.tableWithoutPK).insert(
          TableWithoutPKCompanion.insert(notReallyAnId: 3, someFloat: 7));
      await db.into(db.tableWithoutPK).insert(
          TableWithoutPKCompanion.insert(notReallyAnId: 2, someFloat: 1));

      expect(
        eval(
          db.tableWithoutPK.someFloat
              .sum(filter: db.tableWithoutPK.someFloat.isBiggerOrEqualValue(3)),
          onTable: db.tableWithoutPK,
        ),
        completion(7),
      );
    });
  });

  group('text', () {
    test('contains', () {
      const stringLiteral = Constant('Some sql string literal');
      final containsSql = stringLiteral.contains('sql');

      expect(eval(containsSql), completion(isTrue));
    });

    test('trim()', () {
      const literal = Constant('  hello world    ');
      expect(eval(literal.trim()), completion('hello world'));
    });

    test('trimLeft()', () {
      const literal = Constant('  hello world    ');
      expect(eval(literal.trimLeft()), completion('hello world    '));
    });

    test('trimRight()', () {
      const literal = Constant('  hello world    ');
      expect(eval(literal.trimRight()), completion('  hello world'));
    });
  });

  test('coalesce', () async {
    final expr = coalesce<int>([const Constant(null), const Constant(3)]);

    expect(eval(expr), completion(3));
  });

  test('subquery', () {
    final query = db.selectOnly(db.users)..addColumns([db.users.name]);
    final expr = subqueryExpression<String>(query);

    expect(eval(expr), completion('User name'));
  });

  test('is in subquery', () {
    final query = db.selectOnly(db.users)..addColumns([db.users.name]);
    final match = Variable.withString('User name').isInQuery(query);
    final noMatch = Variable.withString('Another name').isInQuery(query);

    expect(eval(match), completion(isTrue));
    expect(eval(noMatch), completion(isFalse));
  });

  test('groupConcat is nullable', () async {
    final ids = db.users.id.groupConcat();
    final query = db.selectOnly(db.users)
      ..where(db.users.id.equals(999))
      ..addColumns([ids]);

    final result = await query.getSingle();
    expect(result.read(ids), isNull);
  });

  test('subqueries cause updates to stream queries', () async {
    await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(description: 'description'));

    final subquery = subqueryExpression<String>(
        db.selectOnly(db.categories)..addColumns([db.categories.description]));
    final stream = (db.selectOnly(db.users)..addColumns([subquery]))
        .map((row) => row.read(subquery))
        .watchSingle();

    expect(stream, emitsInOrder(['description', 'changed']));

    await db
        .update(db.categories)
        .write(const CategoriesCompanion(description: Value('changed')));
  });

  test('custom expressions can introduces new tables to watch', () async {
    final custom = CustomExpression<int>('1', watchedTables: [db.sharedTodos]);
    final stream = (db.selectOnly(db.users)..addColumns([custom]))
        .map((row) => row.read(custom))
        .watchSingle();

    expect(stream, emitsInOrder([1, 1]));
    db.markTablesUpdated({db.sharedTodos});
  });
}
