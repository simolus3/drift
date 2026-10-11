@TestOn('vm')
library;

import 'package:drift3_preview/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:test/test.dart';

import 'drift_postgres_test.dart';

void main() {
  for (final useBinary in [false, true]) {
    test('binary: $useBinary', () async {
      final executor = PgExecutor();
      final database = _EmptyDatabase(executor.createConnection(), useBinary);

      addTearDown(() => executor.clearDatabaseAndClose(database));

      final object = DatabaseJson({'foo': 'bar'});
      const type = SqlType.json;

      final asVariable = Variable(object, type);
      final asLiteral = Literal(object, type);
      final row = await database.selectExpressions([
        asVariable,
        asLiteral,
      ]).getSingle();
      expect(row.read(asVariable)?.dartValue, object.dartValue);
      expect(row.read(asLiteral)?.dartValue, object.dartValue);
    });
  }
}

final class _EmptyDatabase extends GeneratedDatabase {
  final bool useBinaryJson;

  _EmptyDatabase(super.connection, this.useBinaryJson);

  @override
  DatabaseSchema get schema => const DatabaseSchema([]);

  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
    KnownSqlDialect.postgres: PostgresDialectOptions(useJsonb: useBinaryJson),
  };

  @override
  int get schemaVersion => 1;
}
