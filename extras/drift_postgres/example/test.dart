import 'package:drift/backends.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:drift_postgres/postgres.dart';
import 'package:postgres/postgres_v3_experimental.dart';

void main() async {
  final postgres = PgDatabase(
    endpoint: PgEndpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
    logStatements: true,
  );

  await postgres.ensureOpen(_NullUser());

  final rows = await postgres.runSelect(r'SELECT $1', [true]);
  final row = rows.single;
  print(row);
  print(row.values.map((e) => e.runtimeType).toList());
}

class _NullUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {}

  @override
  int get schemaVersion => 1;
}
