import 'package:drift_dev/src/analysis/results/table.dart';
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
          await backend.driver.fullyAnalyze(Uri.parse('package:a/a.drift'));

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
          await backend.driver.fullyAnalyze(Uri.parse('package:a/a.drift'));

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
          await backend.driver.fullyAnalyze(Uri.parse('package:a/a.drift'));
      expect(stateA, hasNoErrors);

      // Check that `b` has been analyzed and is in cache.
      final stateB =
          backend.driver.cache.knownFiles[Uri.parse('package:a/b.drift')]!;
      expect(stateB, hasNoErrors);

      final a = stateA.analysis.values.single.result!;
      final b = stateB.analysis.values.single.result!;

      expect(a.references, [b]);
    });

    test('non-existing', () async {
      final backend = TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES b (bar)
);
''',
      });

      final state =
          await backend.driver.fullyAnalyze(Uri.parse('package:a/a.drift'));
      expect(state.errorsDuringDiscovery, isEmpty);

      final resultA = state.analysis.values.single;
      expect(resultA.errorsDuringAnalysis,
          [isDriftError('This reference could not be found in any import.')]);
    });
  });
}
