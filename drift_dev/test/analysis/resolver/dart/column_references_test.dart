@Tags(['analyzer'])
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group('reports a warning', () {
    test('when the table is not a class type', () async {
      final state = await TestBackend.inTest(
        {
          'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  TextColumn get foo => text().references(dynamic, #what)();
}
'''
        },
      );

      final file = await state.analyze('package:a/main.dart');
      expect(file.allErrors,
          [isDriftError('`dynamic` is not a class!').withSpan('dynamic')]);
    });

    test('when the column is not a symbol literal', () async {
      final state = await TestBackend.inTest(
        {
          'a|lib/main.dart': '''
import 'package:drift/drift.dart';

const column = #other;

class Foo extends Table {
  TextColumn get foo => text().references(Table, column)();
}
'''
        },
      );

      final file = await state.analyze('package:a/main.dart');
      expect(file.allErrors, [
        isDriftError(startsWith('This should be a symbol literal'))
            .withSpan('column')
      ]);
    });

    test('includes referenced table in database', () async {
      final state = await TestBackend.inTest(
        {
          'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class OtherTable extends Table {
  TextColumn get column => text()();
}

class Foo extends Table {
  TextColumn get foo => text().references(OtherTable, #column)();
}

@DriftDatabase(tables: [Foo])
class Database {}
'''
        },
      );

      final file = await state.analyze('package:a/main.dart');
      state.expectNoErrors();

      final database = file.fileAnalysis!.resolvedDatabases.values.single;

      // Even though the database only includes Foo directly, the reference
      // requires OtherTable to be available as well.
      expect(database.availableElements, hasLength(2));
    });

    test('when the referenced column does not exist', () async {
      final state = await TestBackend.inTest(
        {
          'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class OtherTable extends Table {
  TextColumn get column => text()();
}

class Foo extends Table {
  TextColumn get foo => text().references(OtherTable, #doesNotExist)();
}

@DriftDatabase(tables: [Foo, OtherTable])
class Database {}
'''
        },
      );

      final file = await state.analyze('package:a/main.dart');
      expect(file.allErrors, [
        isDriftError(contains('has no column named `doesNotExist`'))
            .withSpan('#doesNotExist')
      ]);
    });
  });

  test('resolves reference', () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class OtherTable extends Table {
  TextColumn get column => text()();
}

class Foo extends Table {
  TextColumn get foo => text().references(OtherTable, #column,
    onUpdate: KeyAction.restrict, onDelete: KeyAction.cascade)();
}

@DriftDatabase(tables: [Foo, OtherTable])
class Database {}
'''
      },
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final foo = file.analyzedElements
        .whereType<DriftTable>()
        .firstWhere((e) => e.schemaName == 'foo');

    expect(
        foo.references,
        contains(isA<DriftTable>()
            .having((tbl) => tbl.schemaName, 'schemaName', 'other_table')));

    final column = foo.columns.single;
    final constraint =
        column.constraints.whereType<ForeignKeyReference>().first;

    expect(constraint.otherColumn.nameInSql, 'column');
    expect(constraint.otherColumn.owner.schemaName, 'other_table');
    expect(constraint.onUpdate, ReferenceAction.restrict);
    expect(constraint.onDelete, ReferenceAction.cascade);
  });

  test('resolves self-references', () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(Foo, #id)();
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

    expect(foo.references, isEmpty);

    final column = foo.columns[1];
    final constraint =
        column.constraints.whereType<ForeignKeyReference>().first;

    expect(constraint.otherColumn.nameInSql, 'id');
    expect(constraint.otherColumn.owner.schemaName, 'foo');
  });
}
