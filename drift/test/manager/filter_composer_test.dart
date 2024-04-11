import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/matchers.dart';
import '../test_utils/mocks.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late TodoDb db;
  late MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('manager - generates parentheses for OR in AND', () {
    final filterComposer = $$CategoriesTableFilterComposer(db, db.categories);
    final expr = (filterComposer.idValue(1) | filterComposer.idValue(2)) &
        (filterComposer.idValue(3) | filterComposer.idValue(4));
    expect(
        expr.expression,
        generates(
            '("id" = ? OR "id" = ?) AND ("id" = ? OR "id" = ?)', [1, 2, 3, 4]));
  });

  test('manager - equals', () {
    final filterComposer = $$CategoriesTableFilterComposer(db, db.categories);
    // Numeric
    expect(filterComposer.idValue.equals(3).expression,
        generates('"id" = ?', [3]));
    expect(filterComposer.idValue(3).expression, generates('"id" = ?', [3]));
    expect(
        filterComposer.idValue.isNull().expression, generates('"id" IS NULL'));
    // Text
    expect(filterComposer.description.equals("Hi").expression,
        generates('"desc" = ?', ["Hi"]));
    expect(filterComposer.description("Hi").expression,
        generates('"desc" = ?', ["Hi"]));
    expect(filterComposer.description.isNull().expression,
        generates('"desc" IS NULL'));
  });

  // test('manager - combine query with AND ', () {
  //   e.expression.hashCode;

  //   expect(
  //     countAll(filter: e.expression),
  //     generates('WHERE "id" = FILTER (WHERE foo >= ?)', [1, 2]),
  //   );
  // });
}
