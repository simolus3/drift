//@dart=2.9
import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_equality.dart';

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

  test('constant hash and equals', () {
    // these shouldn't be identical, so no const constructor
    final first = Constant('hi'); // ignore: prefer_const_constructors
    final alsoFirst = Constant('hi'); // ignore: prefer_const_constructors
    const second = Constant(3);

    expectEquals(first, alsoFirst);
    expectNotEquals(first, second);
  });
}

void testStringMapping(String dart, String expectedLiteral) {
  final ctx = GenerationContext.fromDb(TodoDb());
  final constant = Constant(dart);

  constant.writeInto(ctx);

  expect(ctx.sql, expectedLiteral);
}
