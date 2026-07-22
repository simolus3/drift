import 'dart:typed_data';

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('maps the variable to sql', () {
    final variable = Variable(
      DateTime.fromMillisecondsSinceEpoch(1551297563000),
    );
    expect(
      variable,
      generatesWithDialect(
        '?1',
        dialect: SqliteDialect.withOptions(
          options: SqliteOptions(storeDateTimesAsText: false),
        ),
        variables: [1551297563],
      ),
    );
  });

  test('maps null to null', () {
    expect(Variable<Object>(null), generates('?1', [null]));
  });

  group('can write variables with wrong type parameter', () {
    test('true', () {
      expect(const Variable<Object>(true), generates('?1', [1]));
    });
    test('false', () {
      expect(const Variable<Object>(false), generates('?1', [0]));
    });

    test('string', () {
      expect(const Variable<Object>('hi'), generates('?1', ['hi']));
    });

    test('int', () {
      expect(const Variable<Object>(123), generates('?1', [123]));
    });

    test('big int', () {
      expect(Variable(BigInt.from(123)), generates('?1', [BigInt.from(123)]));
    });

    test('date time', () {
      const stamp = 12345678;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(stamp * 1000);
      expect(
        Variable(dateTime),
        generatesWithDialect(
          '?1',
          dialect: SqliteDialect.withOptions(
            options: SqliteOptions(storeDateTimesAsText: false),
          ),
          variables: [stamp],
        ),
      );
    });

    test('blob', () {
      final data = Uint8List.fromList([1, 2, 3]);
      expect(Variable(data), generates('?1', [data]));
    });

    test('double', () {
      expect(const Variable(12.3), generates('?1', [12.3]));
    });
  });

  test('writes constants when variables are not supported', () {
    const variable = Variable("hello world'");
    final stmt = const SqliteDialect.withOptions().createCompiler();
    stmt.statement.supportsVariables = false;

    variable.compileWith(stmt);

    expect(stmt.statement.buffer.toString(), "'hello world'''");
  });
}
