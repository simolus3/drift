import 'package:test/test.dart';
import 'package:moor/moor.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

void main() {
  test('maps the variable to sql', () {
    final variable =
        Variable(DateTime.fromMillisecondsSinceEpoch(1551297563000));
    final ctx = GenerationContext.fromDb(TodoDb());

    variable.writeInto(ctx);

    expect('?', ctx.sql);
    expect(ctx.boundVariables, [1551297563]);
  });

  group('can write variables with wrong type parameter', () {
    test('true', () {
      expect(const Variable<dynamic>(true), generates('?', [1]));
    });
    test('false', () {
      expect(const Variable<dynamic>(false), generates('?', [0]));
    });

    test('string', () {
      expect(const Variable<dynamic>('hi'), generates('?', ['hi']));
    });

    test('int', () {
      expect(const Variable<dynamic>(123), generates('?', [123]));
    });

    test('date time', () {
      const stamp = 12345678;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(stamp * 1000);
      expect(Variable<dynamic>(dateTime), generates('?', [stamp]));
    });

    test('blob', () {
      final data = Uint8List.fromList([1, 2, 3]);
      expect(Variable<dynamic>(data), generates('?', [data]));
    });

    test('double', () {
      expect(const Variable<dynamic>(12.3), generates('?', [12.3]));
    });
  });

  test('writes null directly for null values', () {
    const variable = Variable<String?>(null);
    final ctx = GenerationContext.fromDb(TodoDb());

    variable.writeInto(ctx);

    expect('NULL', ctx.sql);
    expect(ctx.boundVariables, isEmpty);
  });
}
