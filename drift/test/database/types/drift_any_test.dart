import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  test('implements == and hashCode', () {
    final a1 = DriftAny('a');
    final a2 = DriftAny('a');
    final b = DriftAny('b');

    expect(a1, equals(a2));
    expect(a2, equals(a1));
    expect(a1.hashCode, a2.hashCode);

    expect(b.hashCode, isNot(a1.hashCode));
    expect(b, isNot(a1));
  });

  test('can be read', () {
    final value = DriftAny(1);
    final types = SqlTypes(false);

    expect(value.readAs(DriftSqlType.any, types), value);
    expect(value.readAs(DriftSqlType.string, types), '1');
    expect(value.readAs(DriftSqlType.int, types), 1);
    expect(value.readAs(DriftSqlType.bool, types), true);
    expect(value.readAs(DriftSqlType.bigInt, types), BigInt.one);
    expect(value.readAs(DriftSqlType.double, types), 1.0);
  });

  test('can be written', () {
    void bogusValue() {}

    expect(Variable(DriftAny(bogusValue)), generates('?', [bogusValue]));
  });
}
