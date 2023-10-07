import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/results/column.dart';
import 'package:drift_dev/src/analysis/results/table.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('reports foreign keys in drift model', () async {
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

    final a = results[0].result! as DriftTable;
    final aFoo = a.columns[0];
    final aBar = a.columns[1];

    final b = results[1].result! as DriftTable;
    final bBar = b.columns[0];

    expect(aFoo.sqlType.builtin, DriftSqlType.int);
    expect(aFoo.nullable, isFalse);
    expect(aFoo.constraints, [isA<PrimaryKeyColumn>()]);
    expect(aFoo.customConstraints, 'PRIMARY KEY');

    expect(aBar.sqlType.builtin, DriftSqlType.int);
    expect(aBar.nullable, isTrue);
    expect(aBar.constraints, [
      isA<ForeignKeyReference>()
          .having((e) => e.otherColumn, 'otherColumn', bBar)
          .having((e) => e.onUpdate, 'onUpdate', isNull)
          .having((e) => e.onDelete, 'onDelete', isNull)
    ]);
    expect(aBar.customConstraints, 'REFERENCES b(bar)');

    expect(bBar.sqlType.builtin, DriftSqlType.int);
    expect(bBar.nullable, isFalse);
    expect(bBar.constraints, isEmpty);
    expect(bBar.customConstraints, 'NOT NULL');
  });

  test('recognizes aliases to rowid', () async {
    final state = TestBackend.inTest({
      'foo|lib/a.drift': '''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      );

      CREATE TABLE users2 (
        id INTEGER,
        name TEXT NOT NULL,
        PRIMARY KEY (id)
      );
      '''
    });

    final result = await state.analyze('package:foo/a.drift');

    final users1 = result.analysis[result.id('users')]!.result as DriftTable;
    final users2 = result.analysis[result.id('users2')]!.result as DriftTable;

    expect(users1.isColumnRequiredForInsert(users1.columns[0]), isFalse);
    expect(users1.isColumnRequiredForInsert(users1.columns[1]), isTrue);

    expect(users2.isColumnRequiredForInsert(users2.columns[0]), isFalse);
    expect(users2.isColumnRequiredForInsert(users2.columns[1]), isTrue);
  });

  test('parses enum columns', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
         import 'enum.dart';

         CREATE TABLE foo (
           fruitIndex ENUM(Fruits) NOT NULL,
           fruitWithGenericIndex ENUM(FruitsWithGeneric) NOT NULL,
           fruitName ENUMNAME(Fruits) NOT NULL,
           anotherIndex ENUM(DoesNotExist) NOT NULL,
           anotherName ENUMNAME(DoesNotExist) NOT NULL
         );
      ''',
      'a|lib/enum.dart': '''
        enum Fruits {
          apple, orange, banana
        }

        enum FruitsWithGeneric<T> {
          apple, orange, banana
        }
      ''',
    });

    final file = await state.analyze('package:a/a.drift');
    final table = file.analyzedElements.single as DriftTable;
    final indexColumn =
        table.columns.singleWhere((c) => c.nameInSql == 'fruitIndex');

    expect(indexColumn.sqlType.builtin, DriftSqlType.int);
    expect(
      indexColumn.typeConverter,
      isA<AppliedTypeConverter>()
          .having(
            (e) => e.expression.toString(),
            'expression',
            contains('EnumIndexConverter<Fruits>'),
          )
          .having((e) => e.dartType.getDisplayString(withNullability: true),
              'dartType', 'Fruits'),
    );

    final withGenericIndexColumn = table.columns
        .singleWhere((c) => c.nameInSql == 'fruitWithGenericIndex');
    expect(withGenericIndexColumn.sqlType.builtin, DriftSqlType.int);
    expect(
      withGenericIndexColumn.typeConverter,
      isA<AppliedTypeConverter>()
          .having(
            (e) => e.expression.toString(),
            'expression',
            contains('EnumIndexConverter<FruitsWithGeneric>'),
          )
          .having(
              (e) => e.dartType.element!.name, 'dartType', 'FruitsWithGeneric'),
    );

    final nameColumn =
        table.columns.singleWhere((c) => c.nameInSql == 'fruitName');

    expect(nameColumn.sqlType.builtin, DriftSqlType.string);
    expect(
      nameColumn.typeConverter,
      isA<AppliedTypeConverter>()
          .having(
            (e) => e.expression.toString(),
            'expression',
            contains('EnumNameConverter<Fruits>'),
          )
          .having((e) => e.dartType.getDisplayString(withNullability: true),
              'dartType', 'Fruits'),
    );

    expect(
      file.allErrors,
      containsAllInOrder([
        isDriftError(contains('Could not find `DoesNotExist`'))
            .withSpan('ENUM(DoesNotExist)'),
        isDriftError(contains('Could not find `DoesNotExist`'))
            .withSpan('ENUMNAME(DoesNotExist)'),
      ]),
    );
  });

  test('does not allow converters for enum columns', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
         import 'enum.dart';

         CREATE TABLE foo (
           fruit ENUM(Fruits) NOT NULL MAPPED BY `MyConverter()`
         );
      ''',
      'a|lib/enum.dart': '''
        import 'package:drift/drift.dart';

        enum Fruits {
          apple, orange, banana
        }

        class MyConverter extends TypeConverter<String, String> {}
      ''',
    });

    final file = await state.analyze('package:a/a.drift');

    expect(
      file.allErrors,
      [
        isDriftError(
                'Multiple type converters applied to this column, ignoring this one.')
            .withSpan('MAPPED BY `MyConverter()`')
      ],
    );
  });

  test('does not allow enum types for non-enums', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
         import 'enum.dart';

         CREATE TABLE foo (
           fruit ENUM(NotAnEnum) NOT NULL
         );
      ''',
      'a|lib/enum.dart': '''
        class NotAnEnum {}
      ''',
    });

    final file = await state.analyze('package:a/a.drift');
    expect(file.analyzedElements, hasLength(1));

    expect(
      file.allErrors,
      contains(isDriftError('Not an enum: `NotAnEnum`')),
    );
  });

  test('supports JSON KEY annotation', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
CREATE TABLE waybills (
    parent    INT      JSON KEY parentDoc        NULL,
    id        INT                            NOT NULL,
    dataType  TEXT                           NOT NULL
);
''',
    });

    final file = await state.analyze('package:a/a.drift');
    state.expectNoErrors();

    final table = file.analyzedElements.single as DriftTable;
    expect(
        table.columnBySqlName['parent'],
        isA<DriftColumn>().having(
            (e) => e.overriddenJsonName, 'overriddenJsonName', 'parentDoc'));
  });

  test('recognizes documentation comments', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
CREATE TABLE IF NOT EXISTS currencies (
  -- The name of this currency
  name TEXT NOT NULL PRIMARY KEY,
  symbol TEXT NOT NULL
);
''',
    });

    final file = await state.analyze('package:a/a.drift');
    state.expectNoErrors();

    final table = file.analyzedElements.single as DriftTable;
    expect(
      table.columnBySqlName['name'],
      isA<DriftColumn>().having((e) => e.documentationComment,
          'documentationComment', '/// The name of this currency'),
    );
  });

  test('can use custom types', () async {
    final state = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'b.dart';

CREATE TABLE foo (
  bar `MyType()` NOT NULL
);
''',
      'a|lib/b.dart': '''
import 'package:drift/drift.dart';

class MyType implements CustomSqlType<String> {}
      ''',
    });

    final file = await state.analyze('package:a/a.drift');
    state.expectNoErrors();

    final table = file.analyzedElements.single as DriftTable;
    final column = table.columns.single;

    expect(column.sqlType.isCustom, isTrue);
    expect(column.sqlType.custom?.dartType.toString(), 'String');
    expect(column.sqlType.custom?.expression.toString(), 'MyType()');
  });
}
