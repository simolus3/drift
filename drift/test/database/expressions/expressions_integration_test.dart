import 'package:drift/drift.dart' hide isNull;
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  group('with default options', () {
    _testWith(() => TodoDb.connect(testInMemoryDatabase()));
  });

  group('storing date times as text', () {
    _testWith(
      () => TodoDb.connect(testInMemoryDatabase())
        ..options = const DriftDatabaseOptions(storeDateTimeAsText: true),
      dateTimeAsText: true,
    );
  });
}

void _testWith(TodoDb Function() openDb, {bool dateTimeAsText = false}) {
  late TodoDb db;

  setUp(() async {
    db = openDb();

    // we selectOnly from users for the lack of a better option. Insert one
    // row so that getSingle works
    await db.into(db.users).insert(
        UsersCompanion.insert(name: 'User name', profilePicture: Uint8List(0)));
  });
  tearDown(() => db.close());

  Future<T?> eval<T extends Object>(Expression<T> expr, {TableInfo? onTable}) {
    final query = db.selectOnly(onTable ?? db.users)..addColumns([expr]);
    return query.getSingle().then((row) => row.read(expr));
  }

  group(
    'DateTime',
    () {
      if (dateTimeAsText) {
        test(
          'UTC-ness is kept when storing date times',
          () async {
            final utc = DateTime.utc(2020, 09, 03, 23, 55);
            final local = DateTime(2020, 09, 03, 23, 55);

            expect(await eval(Variable(utc)), utc);
            expect(await eval(Variable(local)), local);
          },
        );

        test('preserves milliseconds', () async {
          final local = DateTime(2020, 09, 03, 23, 55, 0, 123);

          expect(await eval(Variable(local)), local);
        });
      }

      test('plus and minus', () async {
        const nowExpr = currentDateAndTime;
        final tomorrow = nowExpr + const Duration(days: 1);
        final nowStamp = nowExpr.unixepoch;
        final tomorrowStamp = tomorrow.unixepoch;

        final row = await (db.selectOnly(db.users)
              ..addColumns([nowStamp, tomorrowStamp]))
            .getSingle();

        expect(row.read(tomorrowStamp)! - row.read(nowStamp)!,
            const Duration(days: 1).inSeconds);
      });

      test('extracting values', () {
        final expr = Variable.withDateTime(DateTime.utc(2020, 09, 03, 23, 55));

        expect(eval(expr.year), completion(2020));
        expect(eval(expr.month), completion(9));
        expect(eval(expr.day), completion(3));
        expect(eval(expr.hour), completion(23));
        expect(eval(expr.minute), completion(55));
        expect(eval(expr.second), completion(0));

        expect(eval(expr.date), completion('2020-09-03'));
        expect(eval(expr.modify(const DateTimeModifier.days(3)).date),
            completion('2020-09-06'));
        expect(eval(expr.time), completion('23:55:00'));
        expect(eval(expr.datetime), completion('2020-09-03 23:55:00'));
        expect(eval(expr.julianday),
            completion(closeTo(2459096.496527778, 0.0001)));
        expect(eval(expr.unixepoch), completion(1599177300));
        expect(eval(expr.strftime('%Y-%m-%d %H:%M:%S')),
            completion('2020-09-03 23:55:00'));
      });

      DateTime result(DateTime date) {
        if (dateTimeAsText) {
          // sqlite3 operators on UTC internally, so this is what we want
          return date.toUtc();
        } else {
          // The unix epoch representation always returns local date times, so we
          // need to convert.
          return date.toLocal();
        }
      }

      test('from unix epoch', () {
        final dateTime = DateTime(2022, 07, 23, 22, 44);

        expect(
          eval(DateTimeExpressions.fromUnixEpoch(
              Variable(dateTime.millisecondsSinceEpoch ~/ 1000))),
          completion(result(dateTime)),
        );
      });

      test('modifiers', () {
        final expr = Variable.withDateTime(DateTime.utc(2022, 07, 05));

        expect(eval(expr.modify(const DateTimeModifier.days(2))),
            completion(result(DateTime.utc(2022, 07, 07))));
        expect(eval(expr.modify(const DateTimeModifier.months(-2))),
            completion(result(DateTime.utc(2022, 05, 05))));
        expect(eval(expr.modify(const DateTimeModifier.years(1))),
            completion(result(DateTime.utc(2023, 07, 05))));

        expect(eval(expr.modify(const DateTimeModifier.hours(12))),
            completion(result(DateTime.utc(2022, 07, 05, 12))));
        expect(eval(expr.modify(const DateTimeModifier.minutes(30))),
            completion(result(DateTime.utc(2022, 07, 05, 0, 30))));
        expect(eval(expr.modify(const DateTimeModifier.seconds(30))),
            completion(result(DateTime.utc(2022, 07, 05, 0, 0, 30))));

        expect(eval(expr.modify(const DateTimeModifier.startOfDay())),
            completion(result(DateTime.utc(2022, 07, 05))));
        expect(eval(expr.modify(const DateTimeModifier.startOfMonth())),
            completion(result(DateTime.utc(2022, 07, 01))));
        expect(eval(expr.modify(const DateTimeModifier.startOfYear())),
            completion(result(DateTime.utc(2022, 01, 01))));

        // The original expression is a Tuesday
        expect(eval(expr.modify(DateTimeModifier.weekday(DateTime.tuesday))),
            completion(result(DateTime.utc(2022, 07, 05))));
        expect(
          eval(expr.modify(DateTimeModifier.weekday(DateTime.saturday))),
          completion(result(DateTime.utc(2022, 07, 09))),
        );
      });

      if (!dateTimeAsText) {
        test(
          'modifiers utc/local',
          () {
            final expr = Variable.withDateTime(DateTime.utc(2022, 07, 05));

            // drift interprets date time values as timestamps, so going to UTC
            // means subtracting the UTC offset in SQL. Interpreting that timestamp
            // in dart will effectively add it back, so we have the same value bit
            // without the UTC flag in Dart.
            expect(eval(expr.modify(const DateTimeModifier.utc())),
                completion(DateTime(2022, 07, 05)));

            // And vice-versa (note that original expr is in UTC, this one isn't)
            expect(
                eval(Variable.withDateTime(DateTime(2022, 07, 05))
                    .modify(const DateTimeModifier.localTime())),
                completion(DateTime.utc(2022, 07, 05).toLocal()));
          },
          onPlatform: const {
            'browser':
                Skip('TODO: UTC offsets are unknown in WebAssembly module')
          },
        );
      }

      test('aggregates', () async {
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

        expect(
            eval(db.users.creationTime.min()), completion(result(firstTime)));
        expect(
            eval(db.users.creationTime.max()), completion(result(secondTime)));
        expect(eval(db.users.creationTime.avg()),
            completion(result(DateTime(2021, 5, 10, 12))));
      });
    },
    skip:
        sqlite3Version.versionNumber < 3039000 ? 'Requires sqlite 3.39' : null,
  );

  test('rowid', () {
    expect(eval(db.users.rowId), completion(1));
  });

  group('aggregate', () {
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
