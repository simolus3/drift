@TestOn('vm')
import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  late TodoDb db;

  setUp(() async {
    db = TodoDb(VmDatabase.memory());

    // we selectOnly from users for the lack of a better option. Insert one
    // row so that getSingle works
    await db.into(db.users).insert(
        UsersCompanion.insert(name: 'User name', profilePicture: Uint8List(0)));
  });

  tearDown(() => db.close());

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

  test('datetime.date format', () async {
    final expr = Variable.withDateTime(DateTime(2020, 09, 04, 8, 55));
    final asDate = expr.date;

    final row =
        await (db.selectOnly(db.users)..addColumns([asDate])).getSingle();

    expect(row.read(asDate), '2020-09-04');
  });

  test('text contains', () async {
    const stringLiteral = Constant('Some sql string literal');
    final containsSql = stringLiteral.contains('sql');

    final row =
        await (db.selectOnly(db.users)..addColumns([containsSql])).getSingle();

    expect(row.read(containsSql), isTrue);
  });

  test('coalesce', () async {
    final expr = coalesce<int>([const Constant(null), const Constant(3)]);

    final row = await (db.selectOnly(db.users)..addColumns([expr])).getSingle();

    expect(row.read(expr), equals(3));
  });
}
