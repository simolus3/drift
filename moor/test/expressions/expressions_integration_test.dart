import 'package:moor/moor.dart';
@TestOn('vm')
import 'package:test/test.dart';
import 'package:moor_ffi/moor_ffi.dart';

import '../data/tables/todos.dart';

void main() {
  TodoDb db;

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

  test('text contains', () async {
    const stringLiteral = Constant('Some sql string literal');
    final containsSql = stringLiteral.contains('sql');

    final row =
        await (db.selectOnly(db.users)..addColumns([containsSql])).getSingle();

    expect(row.read(containsSql), isTrue);
  });
}
