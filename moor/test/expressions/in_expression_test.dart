import 'package:test/test.dart';
import 'package:moor/moor.dart';
import 'package:moor/moor.dart' as moor;

import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

void main() {
  test('in expressions are generated', () {
    final innerExpression = GeneratedTextColumn('name', null, true);
    // ignore: deprecated_member_use_from_same_package
    final isInExpression = moor.isIn(innerExpression, ['Max', 'Tobias']);

    final context = GenerationContext.fromDb(TodoDb(null));
    isInExpression.writeInto(context);

    expect(context.sql, 'name IN (?, ?)');
    expect(context.boundVariables, ['Max', 'Tobias']);
  });

  test('not in expressions are generated', () {
    final innerExpression = GeneratedTextColumn('name', null, true);
    // ignore: deprecated_member_use_from_same_package
    final isNotIn = moor.isNotIn(innerExpression, ['Foo', 'Bar']);

    expect(isNotIn, generates('name NOT IN (?, ?)', ['Foo', 'Bar']));
  });
}
