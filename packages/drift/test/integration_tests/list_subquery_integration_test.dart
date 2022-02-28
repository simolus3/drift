@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import '../data/tables/custom_tables.dart';

void main() {
  late CustomTablesDb db;

  setUp(() {
    db = CustomTablesDb(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('collects results for LIST subqueries', () async {
    var results = await db.nested('a').get();
    expect(results, isEmpty);

    final defaults = await db.withDefaults.insertReturning(
        WithDefaultsCompanion.insert(a: const Value('a'), b: const Value(1)));
    final constraints = await db.withConstraints
        .insertReturning(WithConstraintsCompanion.insert(
      a: const Value('one'),
      b: 1,
    ));

    results = await db.nested('a').get();
    expect(results, hasLength(1));

    final result = results.single;
    expect(result.defaults, defaults);
    expect(result.nestedQuery0, [constraints]);
  });
}
