import 'package:moor/src/runtime/components/component.dart';
import 'package:test_api/test_api.dart';
import 'package:moor/moor.dart' as moor;

import '../data/tables/todos.dart';

void main() {
  final innerExpression = moor.GeneratedTextColumn('name', null, true);

  test('IS NULL expressions are generated', () {
    final isNull = moor.isNull(innerExpression);

    final context = GenerationContext(TodoDb(null));
    isNull.writeInto(context);

    expect(context.sql, 'name IS NULL');
  });

  test('IS NOT NULL expressions are generated', () {
    final isNotNull = moor.isNotNull(innerExpression);

    final context = GenerationContext(TodoDb(null));
    isNotNull.writeInto(context);

    expect(context.sql, 'name IS NOT NULL');
  });
}
