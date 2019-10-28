import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  group('string literals', () {
    test('can be written as constants', () {
      testStringMapping('hello world', "'hello world'");
    });

    test('supports escaping snigle quotes', () {
      testStringMapping('what\'s that?', "'what\'\'s that?'");
    });

    test('other chars are not escaped', () {
      testStringMapping('\\\$"', "'\\\$\"'");
    });
  });
}

void testStringMapping(String dart, String expectedLiteral) {
  final ctx = GenerationContext.fromDb(TodoDb(null));
  final constant = Constant(dart);

  constant.writeInto(ctx);

  expect(ctx.sql, expectedLiteral);
}
