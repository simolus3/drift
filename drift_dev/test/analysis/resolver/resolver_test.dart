import 'package:drift/drift.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('from clean state', () {
    test('resolves simple tables', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES b (bar)
);

CREATE TABLE b (
  bar INTEGER NOT NULL
);
''',
      });

      final state =
          await backend.driver.resolveElements(Uri.parse('package:a/a.drift'));

      expect(state, hasNoErrors);
      final results = state.analysis.values.toList();

      final a = results[0].result;
      final b = results[1].result;

      expect(a, isA<DriftTable>());
      expect(b, isA<DriftTable>());

      expect((a as DriftTable).schemaName, 'a');
      expect((b as DriftTable).schemaName, 'b');

      expect(a.references, [b]);
      expect(b.references, isEmpty);
    });
  });

  group('references', () {
    test('self', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES a (foo)
);
''',
      });

      final state =
          await backend.driver.resolveElements(Uri.parse('package:a/a.drift'));

      expect(state, hasNoErrors);

      final a = state.analysis.values.single.result as DriftTable;
      expect(a.references, isEmpty);
    });

    test('across files', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'b.drift';

CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES b (bar)
);
''',
        'a|lib/b.drift': '''
CREATE TABLE b (
  bar INTEGER NOT NULL
);
''',
      });

      final stateA =
          await backend.driver.resolveElements(Uri.parse('package:a/a.drift'));
      expect(stateA, hasNoErrors);

      // Check that `b` has been analyzed and is in cache.
      final stateB =
          backend.driver.cache.knownFiles[Uri.parse('package:a/b.drift')]!;
      expect(stateB, hasNoErrors);

      final a = stateA.analysis.values.single.result!;
      final b = stateB.analysis.values.single.result!;

      expect(a.references, [b]);
    });

    test('for triggers', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
import 'b.drift';

CREATE TRIGGER my_trigger AFTER DELETE ON b BEGIN
  INSERT INTO deleted_b VALUES (old.bar);
END;
''',
        'a|lib/b.drift': '''
CREATE TABLE b (
  bar INTEGER NOT NULL
);

CREATE TABLE deleted_b (
  bar INTEGER NOT NULL
);
''',
      });

      final file = await backend.analyze('package:a/a.drift');
      backend.expectNoErrors();

      final trigger = file.analyzedElements.single as DriftTrigger;
      expect(trigger.references, [
        isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'b'),
        isA<DriftTable>()
            .having((e) => e.schemaName, 'schemaName', 'deleted_b'),
      ]);

      expect(trigger.writes, [
        isA<WrittenDriftTable>()
            .having((e) => e.table.schemaName, 'table.schemaName', 'deleted_b')
            .having((e) => e.kind, 'kind', UpdateKind.insert),
      ]);
    });

    test('for indices', () async {});

    group('non-existing', () {
      test('from table', () async {
        final backend = TestBackend.inTest({
          'a|lib/a.drift': '''
CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES b (bar)
);
''',
        });

        final state = await backend.driver
            .resolveElements(Uri.parse('package:a/a.drift'));
        expect(state.errorsDuringDiscovery, isEmpty);

        final resultA = state.analysis.values.single;
        expect(resultA.errorsDuringAnalysis,
            [isDriftError('`b` could not be found in any import.')]);
      });
      test('in a trigger', () async {
        final backend = TestBackend.inTest(const {
          'foo|lib/a.drift': '''
CREATE TRIGGER IF NOT EXISTS foo BEFORE DELETE ON bar BEGIN
END;
        ''',
        });

        final file = await backend.analyze('package:foo/a.drift');

        expect(
          file.allErrors,
          contains(
            isDriftError(contains('`bar` could not be found in any import'))
                .withSpan('bar'),
          ),
        );
      });
    });
  });

  test('emits warning on invalid import', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': "import 'b.drift';",
    });

    final state = await backend.analyze('package:a/a.drift');
    expect(state.errorsDuringDiscovery, [
      isDriftError(
          contains('The imported file, `package:a/b.drift`, does not exist'))
    ]);
  });
}
