import 'dart:io';

import 'package:drift_dev/src/cli/cli.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:path/path.dart' as p;

import '../utils.dart';
import 'utils.dart';

void main() {
  late TestDriftProject project;

  group(
    'make-migrations',
    () {
      test('default', () async {
        project = await TestDriftProject.create([
          d.dir('lib', [d.file('db.dart', _dbContent)]),
          d.file('build.yaml', """
targets:
  \$default:
    builders:
      drift_dev:
        options:
          databases:
            my_database: lib/db.dart""")
        ]);
        await project.runDriftCli(['make-migrations']);
        expect(
            d
                .file('app/drift_schemas/my_database/drift_schema_v1.json')
                .io
                .existsSync(),
            true);
        // No other files should be created for 1st version
        expect(d.file('app/test').io.existsSync(), false);
        expect(d.file('app/lib/db.steps.dart').io.existsSync(), false);

        // Change the db schema without bumping the version
        File(p.join(project.root.path, 'lib/db.dart'))
            .writeAsStringSync(_dbWithNewColumnWithoutVersionBump);
        // Should throw an error
        try {
          await project.runDriftCli(['make-migrations']);
          fail('Expected an error');
        } catch (e) {
          expect(e, isA<FatalToolError>());
        }

        // Change the db schema and bump the version
        File(p.join(project.root.path, 'lib/db.dart'))
            .writeAsStringSync(_dbWithNewColumnBump);
        await project.runDriftCli(['make-migrations']);
        expect(
            d
                .file('app/drift_schemas/my_database/drift_schema_v2.json')
                .io
                .existsSync(),
            true);
        // Test files should be created
        await d.dir('app/test/drift/my_database', [
          d.file(
            'migration_test.dart',
            allOf(
              IsValidDartFile(anything),
              contains('final db = MyDatabase(schema.newConnection())'),
            ),
          ),
          d.file('generated/schema.dart', IsValidDartFile(anything)),
          d.file('generated/schema_v1.dart', IsValidDartFile(anything)),
          d.file('generated/schema_v2.dart', IsValidDartFile(anything)),
        ]).validate();
        // Steps file should be created
        await d
            .file('app/lib/db.steps.dart', IsValidDartFile(anything))
            .validate();
      });
      test('schema_dir is respected', () async {
        project = await TestDriftProject.create([
          d.dir('lib', [d.file('db.dart', _dbContent)]),
          d.file('build.yaml', """
targets:
  \$default:
    builders:
      drift_dev:
        options:
          schema_dir : schemas/drift
          databases:
            my_database: lib/db.dart""")
        ]);
        await project.runDriftCli(['make-migrations']);
        expect(
            d
                .file('app/schemas/drift/my_database/drift_schema_v1.json')
                .io
                .existsSync(),
            true);
      });

      test('test_dir is respected', () async {
        project = await TestDriftProject.create([
          d.dir('lib', [d.file('db.dart', _dbContent)]),
          d.file('build.yaml', """
targets:
  \$default:
    builders:
      drift_dev:
        options:
          test_dir : custom_test
          databases:
            my_database: lib/db.dart""")
        ]);
        await project.runDriftCli(['make-migrations']);
        File(p.join(project.root.path, 'lib/db.dart'))
            .writeAsStringSync(_dbWithNewColumnBump);
        await project.runDriftCli(['make-migrations']);
        await d
            .file('app/custom_test/my_database/migration_test.dart',
                IsValidDartFile(anything))
            .validate();
      });
    },
  );

  test('supports migrations from higher starting numbers', () async {
    project = await TestDriftProject.create([
      d.dir('lib', [
        d.file('db.dart',
            _dbContent.replaceAll('schemaVersion => 1', 'schemaVersion => 3'))
      ]),
      d.file('build.yaml', """
targets:
  \$default:
    builders:
      drift_dev:
        options:
          databases:
            my_database: lib/db.dart""")
    ]);
    await project.runDriftCli(['make-migrations']);
    File(p.join(project.root.path, 'lib/db.dart')).writeAsStringSync(
        _dbWithNewColumnBump.replaceAll(
            'schemaVersion => 2', 'schemaVersion => 4'));
    await project.runDriftCli(['make-migrations']);
    await d
        .file(
            'app/test/drift/my_database/migration_test.dart',
            allOf([
              IsValidDartFile(anything),
              // Make sure the generated example test works.
              contains('oldVersion: 3,'),
              contains('newVersion: 4,'),
              contains('createOld: v3.DatabaseAtV3.new,'),
              contains('createNew: v4.DatabaseAtV4.new'),
            ]))
        .validate();
  });

  group('suggests data migration test', () {
    test('when adding new column without default', () async {
      project = await TestDriftProject.create([
        d.dir('lib', [
          d.file('db.dart', '''
import 'package:drift/drift.dart';

class Examples extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {
    @override
    int get schemaVersion => 1;
}
''')
        ]),
        d.file('build.yaml', """
targets:
  \$default:
    builders:
      drift_dev:
        options:
          databases:
            my_database: lib/db.dart""")
      ]);
      await project.runDriftCli(['make-migrations']);
      await File(p.join(project.root.path, 'lib/db.dart')).writeAsString('''
import 'package:drift/drift.dart';

class Examples extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {
    @override
    int get schemaVersion => 2;
}
''');

      expect(
        () => project.runDriftCli(['make-migrations'], dropPrints: false),
        prints(allOf(
          contains('Your latest migration might benefit from a test with data'),
          contains('Added column "content" in "examples" without a default'),
        )),
      );
    });
  });
}

const _dbContent = '''
import 'package:drift/drift.dart';

class Examples extends Table {
  BoolColumn get isDraft => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {

    @override
    int get schemaVersion => 1;
}
''';

const _dbWithNewColumnWithoutVersionBump = '''
import 'package:drift/drift.dart';

class Examples extends Table {
  BoolColumn get isDraft => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get newColumn => integer().nullable()();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {

    @override
    int get schemaVersion => 1;
}
''';

const _dbWithNewColumnBump = '''
import 'package:drift/drift.dart';

class Examples extends Table {
  BoolColumn get isDraft => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get newColumn => integer().nullable()();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {

    @override
    int get schemaVersion => 2;
}
''';
