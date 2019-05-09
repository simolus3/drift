import 'package:moor/src/runtime/components/component.dart';
import 'package:test_api/test_api.dart';
import 'package:moor/moor.dart' as moor;

import '../data/tables/todos.dart';

void main() {
  test('in expressions are generated', () {
    final innerExpression = moor.GeneratedTextColumn('name', null, true);
    final isInExpression = moor.isIn(innerExpression, ['Max', 'Tobias']);

    final context = GenerationContext.fromDb(TodoDb(null));
    isInExpression.writeInto(context);

    expect(context.sql, 'name IN (?, ?)');
    expect(context.boundVariables, ['Max', 'Tobias']);
  });
}
