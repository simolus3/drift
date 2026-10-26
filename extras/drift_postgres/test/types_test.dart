import 'package:drift3_preview/drift.dart';
import 'package:drift_postgres/src/dialect.dart';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  const dialect = PostgresDialect.withOptions();

  group('boolean', () {
    final type = SqlType.bool.resolveIn(dialect);

    test('read', () {
      expect(type.dartValue(true), true);
      expect(type.dartValue(false), false);
    });

    test('to postgres constant', () {
      expect(type.sqlLiteral(true), 'TRUE::boolean');
      expect(type.sqlLiteral(false), 'FALSE::boolean');
    });

    test('to postgres variable', () {
      expect(
        type.sqlParameter(null),
        TypedValue(Type.boolean, null, isSqlNull: true),
      );
      expect(type.sqlParameter(true), TypedValue(Type.boolean, true));
      expect(type.sqlParameter(false), TypedValue(Type.boolean, false));
    });
  });
}
