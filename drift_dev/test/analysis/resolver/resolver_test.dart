import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:drift/drift.dart' hide DriftView;
import 'package:drift_dev/src/analysis/driver/driver.dart';
import 'package:drift_dev/src/analysis/driver/state.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('from clean state', () {
    test('resolves simple tables', () async {
      final backend = await TestBackend.inTest({
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

      final state = await backend.driver.resolveElements(
        Uri.parse('package:a/a.drift'),
      );

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
      final backend = await TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES a (foo)
);
''',
      });

      final state = await backend.driver.resolveElements(
        Uri.parse('package:a/a.drift'),
      );

      expect(state, hasNoErrors);

      final a = state.analysis.values.single.result as DriftTable;
      expect(a.references, [a]);
    });

    test('across files', () async {
      final backend = await TestBackend.inTest({
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

      final stateA = await backend.driver.resolveElements(
        Uri.parse('package:a/a.drift'),
      );
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
      final backend = await TestBackend.inTest({
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
        isA<DriftTable>().having(
          (e) => e.schemaName,
          'schemaName',
          'deleted_b',
        ),
      ]);

      expect(trigger.writes, [
        isA<WrittenDriftTable>()
            .having((e) => e.table.schemaName, 'table.schemaName', 'deleted_b')
            .having((e) => e.kind, 'kind', UpdateKind.insert),
      ]);
    });

    test('for view insert triggers', () async {
      final backend = await TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE foo(id INTEGER PRIMARY KEY, name TEXT);
CREATE VIEW foo_view AS SELECT * FROM foo;

CREATE TRIGGER foo_create
INSTEAD OF INSERT ON foo_view
BEGIN
  INSERT INTO foo VALUES (new.id, new.name);
END;
''',
      });

      final file = await backend.analyze('package:a/a.drift');
      backend.expectNoErrors();

      final trigger = file.analyzedElements.whereType<DriftTrigger>().single;
      expect(
        trigger.references,
        unorderedEquals([
          isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'foo'),
          isA<DriftView>().having(
            (e) => e.schemaName,
            'schemaName',
            'foo_view',
          ),
        ]),
      );

      expect(trigger.writes, [
        isA<WrittenDriftTable>()
            .having((e) => e.table.schemaName, 'table.schemaName', 'foo')
            .having((e) => e.kind, 'kind', UpdateKind.insert),
      ]);
    });

    test('for view update triggers', () async {
      final backend = await TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE foo(id INTEGER PRIMARY KEY, name TEXT);
CREATE VIEW foo_view AS SELECT * FROM foo;

CREATE TRIGGER foo_update
INSTEAD OF UPDATE ON foo_view
BEGIN
  UPDATE foo SET name = new.name WHERE id = new.id;
END;
''',
      });

      final file = await backend.analyze('package:a/a.drift');
      backend.expectNoErrors();

      final trigger = file.analyzedElements.whereType<DriftTrigger>().single;
      expect(
        trigger.references,
        unorderedEquals([
          isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'foo'),
          isA<DriftView>().having(
            (e) => e.schemaName,
            'schemaName',
            'foo_view',
          ),
        ]),
      );

      expect(trigger.writes, [
        isA<WrittenDriftTable>()
            .having((e) => e.table.schemaName, 'table.schemaName', 'foo')
            .having((e) => e.kind, 'kind', UpdateKind.update),
      ]);
    });

    test('for view delete triggers', () async {
      final backend = await TestBackend.inTest({
        'a|lib/a.drift': '''
CREATE TABLE foo(id INTEGER PRIMARY KEY, name TEXT);
CREATE VIEW foo_view AS SELECT * FROM foo;

CREATE TRIGGER foo_delete
INSTEAD OF DELETE ON foo_view
BEGIN
  DELETE FROM foo WHERE id = old.id;
END;
''',
      });

      final file = await backend.analyze('package:a/a.drift');
      backend.expectNoErrors();

      final trigger = file.analyzedElements.whereType<DriftTrigger>().single;
      expect(
        trigger.references,
        unorderedEquals([
          isA<DriftTable>().having((e) => e.schemaName, 'schemaName', 'foo'),
          isA<DriftView>().having(
            (e) => e.schemaName,
            'schemaName',
            'foo_view',
          ),
        ]),
      );

      expect(trigger.writes, [
        isA<WrittenDriftTable>()
            .having((e) => e.table.schemaName, 'table.schemaName', 'foo')
            .having((e) => e.kind, 'kind', UpdateKind.delete),
      ]);
    });

    group('non-existing', () {
      test('from table', () async {
        final backend = await TestBackend.inTest({
          'a|lib/a.drift': '''
CREATE TABLE a (
  foo INTEGER PRIMARY KEY,
  bar INTEGER REFERENCES b (bar)
);
''',
        });

        final state = await backend.driver.resolveElements(
          Uri.parse('package:a/a.drift'),
        );
        expect(state.errorsDuringDiscovery, isEmpty);

        final resultA = state.analysis.values.single;
        expect(resultA.errorsDuringAnalysis, [
          isDriftError('`b` could not be found in any import.'),
        ]);
      });
      test('in a trigger', () async {
        final backend = await TestBackend.inTest(const {
          'foo|lib/a.drift': '''
CREATE TRIGGER IF NOT EXISTS foo BEFORE DELETE ON bar BEGIN
END;
        ''',
        });

        final file = await backend.analyze('package:foo/a.drift');

        expect(
          file.allErrors,
          contains(
            isDriftError(
              contains('`bar` could not be found in any import'),
            ).withSpan('bar'),
          ),
        );
      });
    });
  });

  test('emits warning on invalid import', () async {
    final backend = await TestBackend.inTest({
      'a|lib/a.drift': "import 'b.drift';",
    });

    final state = await backend.analyze('package:a/a.drift');
    expect(state.errorsDuringDiscovery, [
      isDriftError(
        contains('The imported file, `package:a/b.drift`, does not exist'),
      ),
    ]);
  });

  test('resolves new file from cached reference', () async {
    // Regression test for https://github.com/simolus3/drift/issues/3829

    const contents = <String, String>{
      'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class TableA extends Table {
  IntColumn get columnA => integer()();
}
''',
      'a|lib/b.dart': '''
import 'package:drift/drift.dart';

import 'a.dart';

class TableB extends Table {
  IntColumn get columnB => integer().references(TableA, #columnA)();
}
''',
      'a|lib/c.dart': '''
import 'package:drift/drift.dart';

import 'b.dart';

class TableC extends Table {
  IntColumn get columnC => integer().references(TableB, #columnB)();
}
''',
    };

    final initial = await TestBackend.inTest(contents);
    final initialB = await initial.analyze('package:a/b.dart');
    initial.expectNoErrors();
    expect((initialB.analyzedElements.single as DriftTable).references, [
      isA<DriftElement>().having((e) => e.id.name, 'name', 'table_a'),
    ]);

    // Create a new backend with access to cached data from the first run.
    final second = await TestBackend.inTest(contents);
    second.driver.cacheReader = _InMemoryCacheReader({
      initialB.ownUri: json.encode(
        initial.driver.serializeState(initialB).serializedData,
      ),
    });
    final c = await second.analyze('package:a/c.dart');
    second.expectNoErrors();

    final table = c.analyzedElements.single as DriftTable;
    expect(table.references, [
      isA<DriftElement>().having((e) => e.id.name, 'name', 'table_b'),
    ]);
  });
}

final class _InMemoryCacheReader implements AnalysisResultCacheReader {
  final Map<Uri, String> _elementCache;

  _InMemoryCacheReader(this._elementCache);

  @override
  bool get findsLocalElementsReliably => false;

  @override
  bool get findsResolvedElementsReliably => false;

  @override
  Future<CachedDiscoveryResults?> readDiscovery(Uri uri) async {
    return null;
  }

  @override
  Future<String?> readElementCacheFor(Uri uri) async {
    final found = _elementCache[uri];
    return found;
  }

  @override
  Future<LibraryElement?> readTypeHelperFor(Uri uri) async {
    return null;
  }
}
