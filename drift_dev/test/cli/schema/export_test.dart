import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift_dev/src/services/schema/schema_isolate.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../utils.dart';

void main() {
  group('exports schema', () {
    test('for drift-file definitions', () async {
      final project = TestDriftProject(Directory('../drift/').absolute);

      final statements =
          await project.collectSchema('test/generated/custom_tables.dart');
      expect(
        statements,
        containsAll(
          [startsWith('CREATE TABLE IF NOT EXISTS "mytable"')],
        ),
      );
      expect(statements, everyElement(endsWith(';')));
    });

    test('generates correct dialect-aware code', () async {
      final project = await TestDriftProject.create([
        d.dir('lib', [
          d.file('test.dart', '''
import 'package:drift/drift.dart';

class Examples extends Table {
  BoolColumn get isDraft => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {}
''')
        ])
      ]);

      final exported = await project.collectSchema('lib/test.dart',
          dialect: SqlDialect.postgres);

      expect(
        exported,
        contains(
          allOf(
            contains(
              'CREATE TABLE IF NOT EXISTS "examples"',
            ),
            // for sqlite, we'd add a CHECK IN (0, 1) constraint to boolean
            // columns. We shouldn't do this for postgres.
            isNot(
              contains('CHECK'),
            ),
          ),
        ),
      );
    });

    test('reports sensible error message on failure', () async {
      final project = await TestDriftProject.create([
        d.dir('lib', [
          d.file('test.dart', '''
import 'package:drift/drift.dart';

class Examples extends Table {
  BoolColumn get isDraft => boolean().withDefault(invalid)();
}

@DriftDatabase(tables: [Examples])
class MyDatabase {}
''')
        ])
      ]);

      await expectLater(
        () => project.collectSchema('lib/test.dart'),
        throwsA(isA<SchemaIsolateException>()
            .having((e) => e.cause, 'cause', isA<IsolateSpawnException>())
            .having((e) => e.startupCodeWrittenTo, 'startupCodeWrittenTo',
                isNot(null))),
      );
    });
  });
}

extension on TestDriftProject {
  Future<List<String>> collectSchema(String source,
      {SqlDialect? dialect}) async {
    final printStatements = <String>[];
    await runZoned(
      () async {
        await runDriftCli([
          'schema',
          'export',
          source,
          if (dialect case final dialect?) '--dialect=${dialect.name}',
        ], dropPrints: false);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, msg) => printStatements.add(msg),
      ),
    );

    return printStatements;
  }
}
