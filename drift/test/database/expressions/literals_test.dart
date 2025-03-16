import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  group('string literals', () {
    test('can be written as constants', () {
      testStringMapping('hello world', "'hello world'");
    });

    test('supports escaping snigle quotes', () {
      testStringMapping('what\'s that?', "'what''s that?'");
    });

    test('other chars are not escaped', () {
      testStringMapping('\\\$"', "'\\\$\"'");
    });
  });

  test('constant hash and equals', () {
    // these shouldn't be identical, so no const constructor
    final first = Literal('hi'); // ignore: prefer_const_constructors
    final alsoFirst = Literal('hi'); // ignore: prefer_const_constructors
    const second = Literal(3);

    expectEquals(first, alsoFirst);
    expectNotEquals(first, second);
  });
}

void testStringMapping(String dart, String expectedLiteral) {
  expect(Literal(dart), generates(expectedLiteral));
}
