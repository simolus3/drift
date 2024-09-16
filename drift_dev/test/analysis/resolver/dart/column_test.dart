import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test(
      'It should rename the table and column name to its snake case version by default',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()();
}

@DriftDatabase(tables: [TestTable])
class Database {}
'''
      },
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'test_table');

    final column = table.columns.single;
    expect(column.nameInSql, 'text_column');
  });

  test('It should rename the table and column name to its snake case version',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()();
}

@DriftDatabase(tables: [TestTable])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.snake),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'test_table');

    final column = table.columns.single;
    expect(column.nameInSql, 'text_column');
  });

  test('It should not rename the table and column name', () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TeStTaBlE extends Table {
  TextColumn get tExTcOlUmN => text()();
}

@DriftDatabase(tables: [TeStTaBlE])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.preserve),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'TeStTaBlE');

    final column = table.columns.single;

    expect(column.nameInSql, 'tExTcOlUmN');
  });
  test('It should rename the table and column name to its camel case version',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get text_column => text()();
}

@DriftDatabase(tables: [TestTable])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.camel),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'testTable');

    final column = table.columns.single;
    expect(column.nameInSql, 'textColumn');
  });
  test(
      'It should rename the table and column name to its constant case version',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()();
}

@DriftDatabase(tables: [TestTable])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.constant),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'TEST_TABLE');

    final column = table.columns.single;
    expect(column.nameInSql, 'TEXT_COLUMN');
  });
  test('It should rename the table and column name to its pascal case version',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test_Table extends Table {
  TextColumn get textColumn => text()();
}

@DriftDatabase(tables: [Test_Table])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.pascal),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'TestTable');

    final column = table.columns.single;
    expect(column.nameInSql, 'TextColumn');
  });
  test('It should rename the table and column name to its lower case version',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()();
}

@DriftDatabase(tables: [TestTable])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.lower),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'testtable');

    final column = table.columns.single;

    expect(column.nameInSql, 'textcolumn');
  });
  test('It should rename the table and column name to its upper case version',
      () async {
    final state = await TestBackend.inTest(
      {
        'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()();
}

@DriftDatabase(tables: [TestTable])
class Database {}
'''
      },
      options:
          DriftOptions.defaults(caseFromDartToSql: CaseFromDartToSql.upper),
    );

    final file = await state.analyze('package:a/main.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(table.schemaName, 'TESTTABLE');

    final column = table.columns.single;
    expect(column.nameInSql, 'TEXTCOLUMN');
  });

  test('recognizes custom column types', () async {
    final state = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class StringArrayType implements CustomSqlType<List<String>> {}

class TestTable extends Table {
  Column<List<String>> get list => customType(StringArrayType())();
}
''',
    });

    final file = await state.analyze('package:a/main.dart');
    state.expectNoErrors();

    final table = file.analyzedElements.whereType<DriftTable>().single;
    final column = table.columns.single;

    expect(column.sqlType.builtin, DriftSqlType.any);
    switch (column.sqlType) {
      case ColumnDriftType():
        break;
      case ColumnCustomType(:final custom):
        expect(custom.dartType.toString(), 'List<String>');
        expect(custom.expression.toString(), 'StringArrayType()');
    }
  });

  group('customConstraint analysis', () {
    test('reports errors', () async {
      final state = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text().customConstraint('NOT NULL invalid')();
}
''',
      });

      final file = await state.analyze('package:a/a.dart');
      expect(file.allErrors, [
        isDriftError(contains(
                'Parse error in customConstraint(): Expected a constraint'))
            .withSpan('invalid'),
      ]);
    });

    test('resolves foreign key references', () async {
      final state = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class ReferencedTable extends Table {
  TextColumn get textColumn => text()();
}

class TestTable extends Table {
  TextColumn get a => text().customConstraint('NOT NULL REFERENCES foo (bar)')();
  TextColumn get b => text().customConstraint('NOT NULL REFERENCES referenced_table (foo)')();
  TextColumn get c => text().customConstraint('NOT NULL REFERENCES referenced_table (text_column)')();
}
''',
      });

      final file = await state.analyze('package:a/a.dart');
      final referencedTable =
          file.analysis[file.id('referenced_table')]!.result! as DriftTable;
      final tableAnalysis = file.analysis[file.id('test_table')]!;

      expect(tableAnalysis.errorsDuringAnalysis, [
        isDriftError('`foo` could not be found in any import.')
            .withSpan(contains('REFERENCES foo (bar)')),
        isDriftError(contains('has no column named `foo`'))
            .withSpan(contains('referenced_table (foo)')),
      ]);

      final testTable = tableAnalysis.result! as DriftTable;
      expect(
        testTable.columnBySqlName['c'],
        isA<DriftColumn>().having(
          (e) => e.constraints,
          'constraints',
          contains(isA<ForeignKeyReference>().having((e) => e.otherColumn,
              'otherColumn', referencedTable.columns.single)),
        ),
      );
    });

    test('warns about missing `NOT NULL`', () async {
      final state = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text().customConstraint('UNIQUE')();
}
''',
      });

      final file = await state.analyze('package:a/a.dart');
      expect(file.allErrors, [
        isDriftError(
                contains('This column is not declared to be `.nullable()`'))
            .withSpan("'UNIQUE'"),
      ]);
    });

    test('applies constraints', () async {
      final state = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()
      .customConstraint('NOT NULL GENERATED ALWAYS AS (\\'\\')')();
}
''',
      });

      final file = await state.analyze('package:a/a.dart');
      state.expectNoErrors();

      final table = file.analyzedElements.single as DriftTable;
      final column = table.columns.single;

      expect(column.nullable, isFalse);
      expect(column.isGenerated, isTrue);
      expect(table.isColumnRequiredForInsert(column), isFalse);
    });

    test('reads default', () async {
      final state = await TestBackend.inTest({
        'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class TestTable extends Table {
  TextColumn get textColumn => text()
      .customConstraint("NOT NULL DEFAULT 'foo'")();
}
''',
      });

      final file = await state.analyze('package:a/a.dart');
      state.expectNoErrors();

      final table = file.analyzedElements.single as DriftTable;
      final column = table.columns.single;

      expect(column.nullable, isFalse);
      expect(column.defaultArgument, isNotNull);
      expect(column.customConstraints, isNotNull);
      expect(table.isColumnRequiredForInsert(column), isFalse);
    });
  });
  test('columns by getter and declaration', () async {
    final state = await TestBackend.inTest({
      'a|lib/a.dart': '''
import 'package:drift/drift.dart';

class Students extends Table {
  @JsonKey('group_id')
  @ReferenceName('students')
  IntColumn get myGroup => integer().references(Groups,#id)();
}

class Teachers extends Table {
  @JsonKey('group_id')
  @ReferenceName('teachers')
  late final myGroup = integer().references(Groups,#id);
}

class Groups extends Table {
  late final id = integer().autoIncrement()();
}

@DriftDatabase(tables: [Groups, Students, Teachers])
class Database {}
''',
    });

    final file = await state.analyze('package:a/a.dart');
    state.expectNoErrors();
    final tables = file.analyzedElements.whereType<DriftTable>();

    final studentTable =
        tables.where((element) => element.schemaName == 'students').single;
    final teacherTable =
        tables.where((element) => element.schemaName == 'teachers').single;
    final studentGroupColumn = studentTable.columns.single;
    final teacherGroupColumn = teacherTable.columns.single;

    // Ensure that the columns are the same
    expect(studentGroupColumn.customConstraints,
        equals(teacherGroupColumn.customConstraints));
    expect(
        studentGroupColumn.nameInDart, equals(teacherGroupColumn.nameInDart));
    expect(studentGroupColumn.nameInSql, equals(teacherGroupColumn.nameInSql));
    expect(studentGroupColumn.sqlType, equals(teacherGroupColumn.sqlType));
    expect(studentGroupColumn.nullable, equals(teacherGroupColumn.nullable));
    expect(studentGroupColumn.overriddenJsonName,
        equals(teacherGroupColumn.overriddenJsonName));

    // Ensure that the correct reference name is set
    expect(studentGroupColumn.referenceName, equals('students'));
    expect(teacherGroupColumn.referenceName, equals('teachers'));
  });
}
