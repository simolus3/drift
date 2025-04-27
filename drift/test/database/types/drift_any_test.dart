import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  const dialect = SqliteDialect();
  final type = SqliteDialect.anyType();

  test('types map null values to null', () {
    expect(type.sqlParameterOrNull(dialect, null), isNull);
  });

  test('keeps `DriftAny` values unchanged', () {
    final values = [
      1,
      'two',
      #whatever,
      1.54,
      String,
      DateTime.now(),
      DateTime.now().toUtc(),
      () {},
    ];

    for (final value in values) {
      expect(type.sqlParameter(dialect, DriftAny(value)), value);
      expect(type.dartValue(dialect, value), DriftAny(value));
    }
  });

  test('maps `DriftAny` to literal', () {
    expect(type.sqlLiteral(dialect, DriftAny(1)), '1');
    expect(type.sqlLiteral(dialect, DriftAny('two')), "'two'");
  });

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

    expect(value.readAs(type, dialect), value);
    expect(value.readAs(BuiltinDriftType.text, dialect), '1');
    expect(value.readAs(BuiltinDriftType.int, dialect), 1);
    expect(value.readAs(BuiltinDriftType.bool, dialect), true);
    expect(value.readAs(BuiltinDriftType.int64, dialect), BigInt.one);
    expect(value.readAs(BuiltinDriftType.double, dialect), 1.0);
  });

  test('can be written', () {
    void bogusValue() {}

    expect(Variable(DriftAny(bogusValue), (_) => type),
        generates('?1', [bogusValue]));
  });
}
