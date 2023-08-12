import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/resolver/intermediate_state.dart';
import 'package:drift_dev/src/analysis/results/element.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('drift files', () {
    test('finds local elements', () async {
      final backend = TestBackend.inTest({
        'a|lib/main.drift': '''
CREATE TABLE foo (bar INTEGER);

CREATE VIEW my_view AS SELECT whatever FROM unknown_table;
''',
      });

      final uri = Uri.parse('package:a/main.drift');
      final state = await backend.driver.findLocalElements(uri);
      final discovered = state.discovery;

      DriftElementId id(String name) => DriftElementId(uri, name);

      expect(state, hasNoErrors);
      expect(
        discovered,
        isA<DiscoveredDriftFile>()
            .having((e) => e.imports, 'imports', isEmpty)
            .having(
          (e) => e.locallyDefinedElements,
          'locallyDefinedElements',
          [
            isA<DiscoveredDriftTable>()
                .having((t) => t.ownId, 'ownId', id('foo')),
            isA<DiscoveredDriftView>()
                .having((v) => v.ownId, 'ownId', id('my_view')),
          ],
        ),
      );
    });

    test('reports syntax errors', () async {
      final backend = TestBackend.inTest({
        'a|lib/main.drift': '''
CREATE TABLE valid_1 (bar INTEGER);

CREATE TABLE EXISTS syntax_error ();

CREATE TABLE valid_2 (bar INTEGER);
''',
      });

      final state = await backend.discoverLocalElements('package:a/main.drift');
      expect(state.errorsDuringDiscovery, [
        isDriftError(contains('Expected a table name')),
      ]);

      // The syntax error should only affect the single statement
      expect(
          state.discovery,
          isA<DiscoveredDriftFile>().having((e) => e.locallyDefinedElements,
              'locallyDefinedElements', hasLength(2)));
    });

    test('warns about duplicate elements', () async {
      final backend = TestBackend.inTest({
        'a|lib/main.drift': '''
CREATE TABLE a (id INTEGER);
CREATE VIEW a AS VALUES(1,2,3);
''',
      });

      final state = await backend.discoverLocalElements('package:a/main.drift');
      expect(state.errorsDuringDiscovery, [
        isDriftError(contains('already defines an element named `a`')),
      ]);

      final result = state.discovery as DiscoveredDriftFile;
      expect(result.locallyDefinedElements, [isA<DiscoveredDriftTable>()]);
    });

    group('imports', () {
      test('are resolved', () async {
        final backend = TestBackend.inTest({
          'a|lib/a.drift': "import 'b.drift';",
          'a|lib/b.drift': "CREATE TABLE foo (bar INTEGER);",
        });

        final state = await backend.discoverLocalElements('package:a/a.drift');
        expect(state, hasNoErrors);
        expect(
          state.discovery,
          isA<DiscoveredDriftFile>().having(
            (e) => e.importDependencies,
            'importDependencies',
            [Uri.parse('package:a/b.drift')],
          ),
        );

        expect(
          backend.driver.cache.knownFiles[Uri.parse('package:a/b.drift')],
          isNull,
          reason: 'Discovering local elements should not prepare other files',
        );
      });

      test('can handle circular imports', () async {
        final backend = TestBackend.inTest({
          'a|lib/a.drift': "import 'a.drift'; import 'b.drift';",
          'a|lib/b.drift': "import 'a.drift';",
        });

        final state = await backend.discoverLocalElements('package:a/a.drift');
        expect(state, hasNoErrors);
      });
    });
  });

  group('dart files', () {
    test('fails for part files', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.dart': '''
part of 'b.dart';
''',
        'a|lib/b.dart': '''
part 'a.dart';
''',
      });

      final uri = Uri.parse('package:a/a.dart');
      final state = await backend.driver.findLocalElements(uri);

      expect(state, hasNoErrors);
      expect(state.discovery, isA<NotADartLibrary>());
    });

    test('finds tables', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer()();
}

class Groups extends Table {
  IntColumn get id => integer()();

  String get tableName => 'my_custom_table';
}
''',
      });

      final uri = Uri.parse('package:a/a.dart');
      final state = await backend.driver.findLocalElements(uri);

      expect(state, hasNoErrors);
      expect(
        state.discovery,
        isA<DiscoveredDartLibrary>().having(
          (e) => e.locallyDefinedElements,
          'locallyDefinedElements',
          [
            isA<DiscoveredDartTable>()
                .having((t) => t.ownId, 'ownId', DriftElementId(uri, 'users')),
            isA<DiscoveredDartTable>().having((t) => t.ownId, 'ownId',
                DriftElementId(uri, 'my_custom_table')),
          ],
        ),
      );
    });

    test('ignores abstract tables', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

abstract class Users extends Table {
  IntColumn get id => integer()();
}

abstract class BaseRelationTable extends Table {
  Column<int?> get parentId;
  Column<int?> get childId;

  @override
  Set<Column> get primaryKey => {parentId, childId};
}
''',
      });

      final uri = Uri.parse('package:a/a.dart');
      final state = await backend.driver.findLocalElements(uri);

      expect(state, hasNoErrors);
      expect(
        state.discovery,
        isA<DiscoveredDartLibrary>().having(
          (e) => e.locallyDefinedElements,
          'locallyDefinedElements',
          [
            isA<DiscoveredDartTable>()
                .having((t) => t.ownId, 'ownId', DriftElementId(uri, 'users')),
          ],
        ),
      );
    });

    test('table name errors', () async {
      final backend = TestBackend.inTest({
        'a|lib/expr.dart': '''
import 'package:drift/drift.dart';

class InvalidExpression extends Table {
  String get tableName => 'foo'.toLowerCase();
}
''',
        'a|lib/getter.dart': '''
import 'package:drift/drift.dart';

class InvalidGetter extends Table {
  String get tableName {
    return '';
  }
}
''',
      });

      for (final source in backend.sourceContents.keys) {
        final state = await backend.driver.findLocalElements(Uri.parse(source));

        expect(
          state.errorsDuringDiscovery,
          [isDriftError(contains('must directly return a string literal'))],
          reason: 'Should report error for $source',
        );
      }
    });

    test('warns about duplicate elements', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class A extends Table {
  IntColumn get id => integer()();

  String get tableName => 'tbl';
}

class B extends Table {
  IntColumn get id => integer()();

  String get tableName => 'tbl';
}
''',
      });

      final state =
          await backend.driver.findLocalElements(Uri.parse('package:a/a.dart'));

      expect(state.errorsDuringDiscovery, [
        isDriftError(contains('already defines an element named `tbl`')),
      ]);

      final result = state.discovery as DiscoveredDartLibrary;
      expect(result.locallyDefinedElements, [
        isA<DiscoveredDartTable>()
            .having((e) => e.dartElement.name, 'dartElement.name', 'A')
      ]);
    });
  });
}
