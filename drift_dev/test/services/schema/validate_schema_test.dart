@TestOn('vm')
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:test/test.dart';

class _TestTable extends Table with TableInfo<Table, Never> {
  @override
  final DatabaseConnectionUser attachedDatabase;

  _TestTable(this.attachedDatabase);

  @override
  List<GeneratedColumn<Object>> get $columns => [
        GeneratedColumn('datetime', actualTableName, false,
            type: DriftSqlType.dateTime),
      ];

  @override
  String get actualTableName => 'foo';

  @override
  TableInfo<Table, Never> createAlias(String alias) {
    throw UnimplementedError();
  }

  @override
  FutureOr<Never> map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnimplementedError();
  }
}

class _TestDatabase extends GeneratedDatabase {
  @override
  late final Iterable<TableInfo<Table, dynamic>> allTables = [_TestTable(this)];

  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions options = DriftDatabaseOptions();

  _TestDatabase.connect(super.connection)
      : super.connect();
}

void main() {
  test('finds mismatch for datetime format', () async {
    final db =
        _TestDatabase.connect(DatabaseConnection(NativeDatabase.memory()))
          ..options = const DriftDatabaseOptions(storeDateTimeAsText: false);
    await db.customSelect('SELECT 1').get(); // Open db, setup tables

    db.options = const DriftDatabaseOptions(storeDateTimeAsText: true);
    // Validation should fail now because datetimes are in the wrong format.

    await expectLater(
      db.validateDatabaseSchema(),
      throwsA(isA<SchemaMismatch>().having((e) => e.toString(), 'toString()',
          contains('Expected TEXT, got INTEGER'))),
    );
  });
}
