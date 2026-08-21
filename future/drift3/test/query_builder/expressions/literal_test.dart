import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group('string literals', () {
    test('can be written as constants', () {
      expect(Literal('hello world'), generates("'hello world'"));
    });

    test('supports escaping snigle quotes', () {
      expect(Literal('what\'s that?'), generates("'what''s that?'"));
    });

    test('other chars are not escaped', () {
      expect(Literal('\\\$"'), generates("'\\\$\"'"));
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
