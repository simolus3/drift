@Tags(['analyzer'])
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('parses enum columns', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
         import 'enum.dart';

         CREATE TABLE foo (
           fruit ENUM(Fruits) NOT NULL,
           another ENUM(DoesNotExist) NOT NULL
         );
      ''',
      'foo|lib/enum.dart': '''
        enum Fruits {
          apple, orange, banane
        }
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');
    final table = file.currentResult!.declaredTables.single;
    final column = table.columns.singleWhere((c) => c.name.name == 'fruit');

    state.close();

    expect(column.type, ColumnType.integer);
    expect(
      column.typeConverter,
      isA<UsedTypeConverter>()
          .having(
            (e) => e.expression,
            'expression',
            contains('EnumIndexConverter<Fruits>'),
          )
          .having(
            (e) => e.mappedType.getDisplayString(withNullability: false),
            'mappedType',
            'Fruits',
          ),
    );

    expect(
      file.errors.errors,
      contains(
        isA<MoorError>().having(
          (e) => e.message,
          'message',
          contains('Type DoesNotExist could not be found'),
        ),
      ),
    );
  });

  test('does not allow converters for enum columns', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
         import 'enum.dart';
         
         CREATE TABLE foo (
           fruit ENUM(Fruits) NOT NULL MAPPED BY `MyConverter()`
         );
      ''',
      'foo|lib/enum.dart': '''
        import 'package:drift/drift.dart';
      
        enum Fruits {
          apple, orange, banane
        }
        
        class MyConverter extends TypeConverter<String, String> {}  
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');
    state.close();

    expect(
      file.errors.errors,
      contains(
        isA<MoorError>().having(
          (e) => e.message,
          'message',
          contains("can't apply another converter"),
        ),
      ),
    );
  });

  test('does not allow enum types for non-enums', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
         import 'enum.dart';
         
         CREATE TABLE foo (
           fruit ENUM(NotAnEnum) NOT NULL
         );
      ''',
      'foo|lib/enum.dart': '''
        class NotAnEnum {}
      ''',
    });

    final file = await state.analyze('package:foo/a.moor');
    state.close();

    expect(
      file.errors.errors,
      contains(
        isA<ErrorInMoorFile>()
            .having(
              (e) => e.message,
              'message',
              allOf(contains('NotAnEnum'), contains('Not an enum')),
            )
            .having((e) => e.span.text, 'span', 'ENUM(NotAnEnum)'),
      ),
    );
  });
}
