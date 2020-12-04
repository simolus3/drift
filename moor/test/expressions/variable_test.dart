//@dart=2.9
import 'package:test/test.dart';
import 'package:moor/moor.dart';

import '../data/tables/todos.dart';

void main() {
  test('maps the variable to sql', () {
    final variable =
        Variable(DateTime.fromMillisecondsSinceEpoch(1551297563000));
    final ctx = GenerationContext.fromDb(TodoDb());

    variable.writeInto(ctx);

    expect('?', ctx.sql);
    expect(ctx.boundVariables, [1551297563]);
  });

  test('writes null directly for null values', () {
    const variable = Variable<String>(null);
    final ctx = GenerationContext.fromDb(TodoDb());

    variable.writeInto(ctx);

    expect('NULL', ctx.sql);
    expect(ctx.boundVariables, isEmpty);
  });
}
