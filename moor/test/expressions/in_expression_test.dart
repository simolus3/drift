import 'package:test/test.dart';
import 'package:moor/moor.dart';
import 'package:moor/moor.dart' as moor;

import '../data/tables/todos.dart';

void main() {
  test('in expressions are generated', () {
    final innerExpression = GeneratedTextColumn('name', null, true);
    final isInExpression = moor.isIn(innerExpression, ['Max', 'Tobias']);

    final context = GenerationContext.fromDb(TodoDb(null));
    isInExpression.writeInto(context);

    expect(context.sql, 'name IN (?, ?)');
    expect(context.boundVariables, ['Max', 'Tobias']);
  });
}
