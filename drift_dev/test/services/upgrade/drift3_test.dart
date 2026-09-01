import 'package:drift_dev/src/cli/project.dart';
import 'package:drift_dev/src/services/upgrade/drift3.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../cli/utils.dart';

Future<TestDriftProject> _drift2Project(
  Iterable<d.Descriptor> lib, {
  String? pubspec,
  Iterable<d.Descriptor>? additional,
}) {
  return TestDriftProject.create([
    d.dir('lib', lib),
    if (pubspec != null) d.file('pubspec.yaml', pubspec),
    ...?additional,
  ]);
}

void main() {
  group('migrates Dart sources', () {
    test('migrates imports', () async {
      final original = await _drift2Project([
        d.file('database.dart', '''
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift_dev/api/migrations_native.dart';
'''),
      ]);
      await original.migrateToDrift3();

      await d.file('app/lib/database.dart', '''
import 'dart:typed_data';
import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/web.dart';
import 'package:drift_sqlite/schema_verifier.dart';
''').validate();
    });

    test('migrates table definitions', () async {
      final original = await _drift2Project([
        d.file('database.dart', '''
import 'package:drift/drift.dart';

@DataClassName('TodoEntry')
class TodoEntries extends Table with AutoIncrementingPrimaryKey {
  TextColumn get description => text()();
  IntColumn get category => integer().nullable().references(Categories, #id)();
  DateTimeColumn get dueDate => dateTime().nullable()();

  late final otherSyntax = text()();
}
'''),
      ]);
      await original.migrateToDrift3();

      await d.file('app/lib/database.dart', '''
import 'dart:typed_data';
import 'package:drift3_preview/drift.dart';

@DataClassName('TodoEntry')
class TodoEntries extends Table with AutoIncrementingPrimaryKey {
  TextColumn get description => text();
  IntColumn get category => integer().nullable().references(Categories, #id);
  DateTimeColumn get dueDate => dateTime().nullable();

  Column<String> get otherSyntax => text();
}
''').validate();
    });

    test('migrates renamed identifiers', () async {
      final original = await _drift2Project([
        d.file('database.dart', '''
import 'package:drift/drift.dart';

Expression<bool> m(Expression<int> a, Expression<int> b) {
  return a.isBiggerOrEqual(b);
}
'''),
      ]);
      await original.migrateToDrift3();

      await d.file('app/lib/database.dart', '''
import 'dart:typed_data';
import 'package:drift3_preview/drift.dart';

Expression<bool> m(Expression<int> a, Expression<int> b) {
  return a.isGreaterOrEqual(b);
}
''').validate();
    });

    test('migrates common apis', () async {
      final original = await _drift2Project([
        d.file('database.dart', '''
import 'package:drift/drift.dart';

class FakeGeneratedDatabase extends GeneratedDatabase {
  TableInfo get users => throw 'stub';
}

void queryExtension(FakeGeneratedDatabase db) {
  db.users.insertOne('stub');
  db.users.actualTableName; // not a query extension
  final x = db.users;
  x.insertOne('stub'); // indirect, cannot be migrated
}

void rawConnection(FakeGeneratedDatabase db) async {
  db.executor.dialect;
  await db.executor.ensureOpen(db);
  await db.executor.close();
}

void insertMode(FakeGeneratedDatabase db) async {
  final stmt = db.into(db.users);
  await stmt.insert(stub, mode: InsertMode.replace);
  await db.users.insertOne(stub);
  await db.users.insertOne(stub, mode: InsertMode.insertOrReplace);
}
'''),
      ]);
      await original.migrateToDrift3();
      await d.file('app/lib/database.dart', '''
import 'dart:typed_data';
import 'package:drift3_preview/drift.dart';

class FakeGeneratedDatabase extends GeneratedDatabase {
  TableInfo get users => throw 'stub';
}

void queryExtension(FakeGeneratedDatabase db) {
  db.usersQueries.insertOne('stub');
  db.users.actualTableName; // not a query extension
  final x = db.users;
  x.insertOne('stub'); // indirect, cannot be migrated
}

void rawConnection(FakeGeneratedDatabase db) async {
  db.dialect.known;
  await db.initialize();
  await (await db.currentSession()).close();
}

void insertMode(FakeGeneratedDatabase db) async {
  final stmt = db.into(db.users);
  await stmt.mode(InsertMode.replace).insert(stub, );
  await db.usersQueries.insertOne(stub);
  await db.usersQueries.insertOneMode(InsertMode.insertOrReplace, stub, );
}
''').validate();
    });
  });

  test('migrates pubspec.yaml', () async {
    final original = await _drift2Project(
      [],
      pubspec: r'''
name: my_app
environment:
  sdk: ^3.12.0

dependencies:
  drift: ^2.34.0

dev_dependencies:
  build_runner:
  drift_dev: ^2.34.0
''',
    );
    await original.migrateToDrift3();

    await d.file('app/pubspec.yaml', r'''
name: my_app
environment:
  sdk: ^3.12.0

dependencies:
  drift3_preview: ^3.0.0-0
  drift_manager: ^1.0.0-0
  drift_sqlite: ^1.0.0-0

dev_dependencies:
  build_runner:
  drift_dev: ^2.34.0
''').validate();
  });

  group('migrates build.yaml', () {
    test('migrates dialect options', () async {
      // Drift3 has different defaults, so a project without any configuration
      // options needs one now to stay compatible.
      final empty = await _drift2Project(
        [],
        additional: [
          d.file('build.yaml', r'''
targets:
  $default:
    builders:
      drift_dev:
        options:
          named_parameters: true
          store_date_time_values_as_text: true
          sql:
            dialects: [sqlite, postgres]
            options:
              modules: [fts5]
'''),
        ],
      );
      await empty.migrateToDrift3();

      await d.file('app/build.yaml', r'''
targets:
  $default:
    builders:
      drift_dev:
        options:
          named_parameters: true
          dialects:
            - dialect: sqlite
              modules:
                - fts5
              strict_tables_by_default: false
              use_binary_json_representation: false
              store_date_times_as_text: true
            - dialect: postgres
          drift3_preview: true
''').validate();
    });

    test('creates one by default', () async {
      // Drift3 has different defaults, so a project without any configuration
      // options needs one now to stay compatible.
      final empty = await _drift2Project([]);
      await empty.migrateToDrift3();

      await d.file('app/build.yaml', r'''
targets:
  $default:
    builders:
      drift_dev:
        options:
          drift3_preview: true
          dialects:
            - dialect: sqlite
              strict_tables_by_default: false
              use_binary_json_representation: false
              store_date_times_as_text: false''').validate();
    });

    test('adds drift options', () async {
      final empty = await _drift2Project(
        [],
        additional: [
          d.file('build.yaml', r'''
targets:
  $default:
    sources:
      exclude: ['foo/bar']
'''),
        ],
      );
      await empty.migrateToDrift3();
      await d.file('app/build.yaml', r'''
targets:
  $default:
    builders:
      drift_dev:
        options:
          drift3_preview: true
          dialects:
            - dialect: sqlite
              strict_tables_by_default: false
              use_binary_json_representation: false
              store_date_times_as_text: false
    sources:
      exclude: ['foo/bar']
''').validate();
    });
  });
}

extension on TestDriftProject {
  Future<void> migrateToDrift3() async {
    final project = await DriftProject.readFromDir(root);
    await UpgradeToDrift3(project).upgrade();
  }
}
