import 'package:test/test.dart';

void expectEquals(dynamic a, dynamic expected) {
  expect(a, equals(expected));
  expect(a.hashCode, equals(expected.hashCode));
}

void expectNotEquals(dynamic a, dynamic expected) {
  expect(a, isNot(equals(expected)));
  expect(a.hashCode, isNot(equals(expected.hashCode)));
}
