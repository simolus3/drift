import 'package:sally/src/runtime/components/component.dart';
import 'package:test_api/test_api.dart';
import 'package:sally/sally.dart' as sally;

import '../data/tables/todos.dart';

void main() {
  final innerExpression = sally.GeneratedTextColumn('name', true);

  test('IS NULL expressions are generated', () {
    final isNull = sally.isNull(innerExpression);

    final context = GenerationContext(TodoDb(null));
    isNull.writeInto(context);

    expect(context.sql, 'name IS NULL');
  });

  test('IS NOT NULL expressions are generated', () {
    final isNotNull = sally.isNotNull(innerExpression);

    final context = GenerationContext(TodoDb(null));
    isNotNull.writeInto(context);

    expect(context.sql, 'name IS NOT NULL');
  });
}
