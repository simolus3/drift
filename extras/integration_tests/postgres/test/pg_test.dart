import 'dart:io';

import 'package:drift/postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:tests/tests.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(PgDatabase.open(
        'localhost', 5432, 'postgres',
        username: 'postgres', password: 'postgres'));
  }

  @override
  Future deleteData() async {
    final connection = PostgreSQLConnection('localhost', 5432, 'postgres',
        username: 'postgres', password: null);
    await connection.open();
    await connection.query('DROP SCHEMA public CASCADE;');
    await connection.query('CREATE SCHEMA public;');
    await connection.query('GRANT ALL ON SCHEMA public TO postgres;');
    await connection.query('GRANT ALL ON SCHEMA public TO public;');
    await connection.query('CREATE DOMAIN BLOB AS BYTEA;');
    await connection.close();
  }
}

void main() {
  runAllTests(PgExecutor());
}
