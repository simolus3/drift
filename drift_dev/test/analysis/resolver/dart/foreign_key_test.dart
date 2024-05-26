import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group('reports a warning', () {
    test('when the table is not a class type', () async {
      final backend = await TestBackend.inTest({
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  TextColumn get foo => text().references(dynamic, #what)();
}
'''
      });

      final file = await backend.driver
          .resolveElements(Uri.parse('package:a/main.dart'));
      expect(file.errorsDuringDiscovery, isEmpty);

      final result = file.analysis.values.single;
      expect(result.result, isA<DriftTable>());
      expect(result.errorsDuringAnalysis, [
        isDriftError('`dynamic` is not a class!').withSpan('dynamic'),
      ]);
    });

    test('when the table is not a symbol literal', () async {
      final backend = await TestBackend.inTest({
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

const column = #other;

class Foo extends Table {
  TextColumn get foo => text().references(Table, column)();
}
'''
      });

      final file = await backend.driver
          .resolveElements(Uri.parse('package:a/main.dart'));
      expect(file.errorsDuringDiscovery, isEmpty);

      final result = file.analysis.values.single;
      expect(result.result, isA<DriftTable>());
      expect(result.errorsDuringAnalysis, [
        isDriftError(contains('This should be a symbol literal'))
            .withSpan('column'),
      ]);
    });

    test('when the referenced table does not exist', () async {
      final backend = await TestBackend.inTest({
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class OtherTable {
  // not a table!
}

class Foo extends Table {
  TextColumn get foo => text().references(OtherTable, #column)();
}
'''
      });

      final file = await backend.driver
          .resolveElements(Uri.parse('package:a/main.dart'));
      expect(file.errorsDuringDiscovery, isEmpty);

      final result = file.analysis.values.single;
      expect(result.result, isA<DriftTable>());
      expect(result.errorsDuringAnalysis, [
        isDriftError('The referenced element, OtherTable, is not understood by '
                'drift.')
            .withSpan('OtherTable'),
      ]);
    });
  });

  test('resolves reference', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class OtherTable extends Table {
  TextColumn get column => text()();
}

class Foo extends Table {
  TextColumn get foo => text().references(OtherTable, #column,
    onUpdate: KeyAction.restrict, onDelete: KeyAction.cascade)();
}
'''
    });

    final uri = Uri.parse('package:a/main.dart');
    final file = await backend.driver.resolveElements(uri);
    final otherTable =
        file.analysis[DriftElementId(uri, 'other_table')]!.result as DriftTable;
    final foo = file.analysis[DriftElementId(uri, 'foo')]!.result as DriftTable;

    expect(foo.references, [otherTable]);

    final column = foo.columns.single;
    final feature = column.constraints.whereType<ForeignKeyReference>().first;

    expect(feature.otherColumn.nameInDart, 'column');
    expect(feature.otherColumn.owner, otherTable);
    expect(feature.onUpdate, ReferenceAction.restrict);
    expect(feature.onDelete, ReferenceAction.cascade);
  });

  test('resolves self-references', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(Foo, #id)();
}
'''
    });

    final file =
        await backend.driver.resolveElements(Uri.parse('package:a/main.dart'));
    final table = file.analysis.values.single.result as DriftTable;

    expect(table.references, isEmpty);

    final id = table.columns[0];
    final parentId = table.columns[1];

    expect(
        parentId.constraints,
        contains(isA<ForeignKeyReference>()
            .having((e) => e.otherColumn, 'otherColumn', id)));
  });

  test('parses initially deferred mode', () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(Foo, #id, initiallyDeferred: true)();
  TextColumn get otherTest => text().references(Others, #test, initiallyDeferred: true)();
}

class Others extends Table {
  TextColumn get test => text()();
}

@DriftDatabase(tables: [Foo])
class Database {}
'''
      },
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final foo = file.analyzedElements.firstWhere((e) => e.id.name == 'foo')
        as DriftTable;

    final column = foo.columns[1];
    final constraint =
        column.constraints.whereType<ForeignKeyReference>().first;

    expect(constraint.otherColumn.nameInSql, 'id');
    expect(constraint.initiallyDeferred, isTrue);

    final otherColumn = foo.columns[2];
    final otherConstraint =
        otherColumn.constraints.whereType<ForeignKeyReference>().first;

    expect(otherConstraint.otherColumn.nameInSql, 'test');
    expect(otherConstraint.initiallyDeferred, isTrue);
  });

  test('parses reference from SQL', () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get otherTest => text().customConstraint('NOT NULL REFERENCES "others" (test) DEFERRABLE INITIALLY DEFERRED')();
}

class Others extends Table {
  TextColumn get test => text()();
}

@DriftDatabase(tables: [Foo])
class Database {}
'''
      },
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final foo = file.analyzedElements.firstWhere((e) => e.id.name == 'foo')
        as DriftTable;

    final column = foo.columns[1];
    final constraint =
        column.constraints.whereType<ForeignKeyReference>().first;
    expect(constraint.otherColumn.nameInSql, 'test');
    expect(constraint.initiallyDeferred, isTrue);
  });
}
