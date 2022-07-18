import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

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
      expect(const Variable<Object>(true), generates('?', [1]));
    });
    test('false', () {
      expect(const Variable<Object>(false), generates('?', [0]));
    });

    test('string', () {
      expect(const Variable<Object>('hi'), generates('?', ['hi']));
    });

    test('int', () {
      expect(const Variable<Object>(123), generates('?', [123]));
    });

    test('big int', () {
      expect(Variable(BigInt.from(123)), generates('?', [BigInt.from(123)]));
    });

    test('date time', () {
      const stamp = 12345678;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(stamp * 1000);
      expect(Variable(dateTime), generates('?', [stamp]));
    });

    test('blob', () {
      final data = Uint8List.fromList([1, 2, 3]);
      expect(Variable(data), generates('?', [data]));
    });

    test('double', () {
      expect(const Variable(12.3), generates('?', [12.3]));
    });
  });

  test('writes null directly for null values', () {
    const variable = Variable<String>(null);
    final ctx = GenerationContext.fromDb(TodoDb());

    variable.writeInto(ctx);

    expect(ctx.sql, 'NULL');
    expect(ctx.boundVariables, isEmpty);
  });

  test('writes constants when variables are not supported', () {
    const variable = Variable("hello world'");
    final ctx = GenerationContext.fromDb(TodoDb(), supportsVariables: false);
    variable.writeInto(ctx);

    expect(ctx.sql, "'hello world'''");
  });
}
