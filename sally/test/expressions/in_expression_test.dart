import 'package:sally/src/runtime/components/component.dart';
import 'package:test_api/test_api.dart';
import 'package:sally/sally.dart' as sally;

import '../data/tables/todos.dart';

void main() {
  test('in expressions are generated', () {
    final innerExpression = sally.GeneratedTextColumn('name', true);
    final isInExpression = sally.isIn(innerExpression, ['Max', 'Tobias']);

    final context = GenerationContext(TodoDb(null));
    isInExpression.writeInto(context);

    expect(context.sql, 'name IN (?, ?)');
    expect(context.boundVariables, ['Max', 'Tobias']);
  });
}