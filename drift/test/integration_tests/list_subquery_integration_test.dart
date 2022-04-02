import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/custom_tables.dart';
import '../test_utils/test_utils.dart';

void main() {
  late CustomTablesDb db;

  setUp(() {
    db = CustomTablesDb.connect(testInMemoryDatabase());
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
