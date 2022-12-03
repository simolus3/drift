import 'package:drift_dev/src/analysis/options.dart';
import 'package:drift_dev/src/analysis/results/table.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test(
      'It should rename the table and column name to its snake case version by default',
      () async {
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
    final state = TestBackend.inTest(
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
}
