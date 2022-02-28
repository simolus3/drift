@Tags(['analyzer'])
import 'package:drift_dev/src/model/column.dart';
import 'package:drift_dev/src/model/table.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('reports a warning', () {
    test('when the table is not a class type', () async {
      final state = TestState.withContent(
        {
          'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Foo extends Table {
  TextColumn get foo => text().references(dynamic, #what)();
}
'''
        },
      );
      addTearDown(state.close);

      final file = await state.analyze('package:a/main.dart');
      file.expectDartError('dynamic is not a class!', 'dynamic');
    });

    test('when the column is not a symbol literal', () async {
      final state = TestState.withContent(
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
      addTearDown(state.close);

      final file = await state.analyze('package:a/main.dart');
      file.expectDartError(
          startsWith('This should be a symbol literal'), 'column');
    });

    test('when the referenced table does not exist', () async {
      final state = TestState.withContent(
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
      addTearDown(state.close);

      final file = await state.analyze('package:a/main.dart');
      file.expectDartError(
          startsWith('This class has not been added as a table'), 'OtherTable');
    });

    test('when the referenced column does not exist', () async {
      final state = TestState.withContent(
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
      addTearDown(state.close);

      final file = await state.analyze('package:a/main.dart');
      file.expectDartError(
          contains('does not declare a column named'), '#doesNotExist');
    });
  });

  test('resolves reference', () async {
    final state = TestState.withContent(
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
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.dart');
    expect(file.errors.errors, isEmpty);

    final foo = file.currentResult!.declaredTables
        .firstWhere((e) => e.sqlName == 'foo');

    expect(
        foo.references,
        contains(isA<MoorTable>()
            .having((tbl) => tbl.sqlName, 'sqlName', 'other_table')));

    final column = foo.columns.single;
    final feature =
        column.features.whereType<ResolvedDartForeignKeyReference>().first;

    expect(feature.otherColumn.name.name, 'column');
    expect(feature.otherTable.sqlName, 'other_table');
    expect(feature.onUpdate, ReferenceAction.restrict);
    expect(feature.onDelete, ReferenceAction.cascade);
  });
}
