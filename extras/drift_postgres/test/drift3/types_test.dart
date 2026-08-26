import 'package:drift/src/drift3_preview/drift.dart';
import 'package:drift_postgres/src/drift3_preview/dialect.dart';
import 'package:drift_postgres/src/drift3_preview/type.dart';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  const dialect = PostgresDialect.withOptions();

  group('boolean', () {
    final type = BuiltinDriftType.bool.resolveIn(dialect);

    test('read', () {
      expect(type.dartValue(fakeValue(Type.boolean, true)), true);
      expect(type.dartValue(fakeValue(Type.boolean, false)), false);
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

PostgresDatabaseValue fakeValue(Type type, Object value) {
  return PostgresDatabaseValue(
    column: ResultSchemaColumn(typeOid: 0, type: type),
    value: value,
  );
}
