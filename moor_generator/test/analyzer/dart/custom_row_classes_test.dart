@Tags(['analyzer'])
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/model/base_entity.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  late TestState state;

  setUpAll(() {
    state = TestState.withContent({
      'a|lib/invalid_no_unnamed_constructor.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass.create();
}
@UseRowClass(RowClass)
class TableClass extends Table {}
      ''',
      'a|lib/invalid_no_named_constructor.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass();
  RowClass.create();
}
@UseRowClass(RowClass, constructor: 'create2')
class TableClass extends Table {}
      ''',
      'a|lib/mismatching_type.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass(int x);
}
@UseRowClass(RowClass)
class TableClass extends Table {
  TextColumn get x => text()();
}
      ''',
      'a|lib/mismatching_nullability.dart': '''
import 'package:moor/moor.dart';

class RowClass {
  RowClass(int x);
}
@UseRowClass(RowClass)
class TableClass extends Table {
  IntColumn get x => integer().nullable()();
}
      ''',
      'a|lib/mismatching_type_converter.dart': '''
import 'package:moor/moor.dart';

class MyConverter extends TypeConverter<int, String> {
  const MyConverter();

  @override
  int? mapToDart(String? fromDb) => throw 'stub';
  @override
  String? mapToSql(int? value) => throw 'stub';
}

class RowClass {
  RowClass(String x);
}

@UseRowClass(RowClass)
class TableClass extends Table {
  TextColumn get x => text().map(const MyConverter())();
}
      ''',
      'a|lib/generic.dart': '''
//@dart=2.13
import 'package:moor/moor.dart';

typedef StringRow = GenericRow<String>;
typedef IntRow = GenericRow<int>;

class GenericRow<T> {
  final T value;
  GenericRow(this.value);
}

@UseRowClass(StringRow)
class StringTable extends Table {
  TextColumn get value => text()();
}

@UseRowClass(IntRow)
class IntTable extends Table {
  IntColumn get value => integer()();
}
      '''
    });
  });

  tearDownAll(() => state.close());

  group('warns about misuse', () {
    test('when the desired row class does not have an unnamed constructor',
        () async {
      final file =
          await state.analyze('package:a/invalid_no_unnamed_constructor.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            contains('must have an unnamed constructor'))),
      );
    });

    test('when no constructor with the right name exists', () async {
      final file =
          await state.analyze('package:a/invalid_no_named_constructor.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            contains('does not have a constructor named create2'))),
      );
    });

    test('when a parameter has a mismatching type', () async {
      final file = await state.analyze('package:a/mismatching_type.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            contains('Parameter must accept String'))),
      );
    });

    test('when a parameter should be nullable', () async {
      final file =
          await state.analyze('package:a/mismatching_nullability.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>().having((e) => e.message, 'message',
            'Expected this parameter to be nullable')),
      );
    });

    test('when a parameter has a mismatching type converter', () async {
      final file =
          await state.analyze('package:a/mismatching_type_converter.dart');
      expect(
        file.errors.errors,
        contains(isA<ErrorInDartCode>()
            .having((e) => e.message, 'message', 'Parameter must accept int')),
      );
    });
  });

  test('supports generic row classes', () async {
    final file = await state.analyze('package:a/generic.dart');
    expect(file.errors.errors, isEmpty);

    final tables = (file.currentResult as ParsedDartFile).declaredTables;
    final stringTable = tables.firstWhere((e) => e.dslName == 'StringTable');
    final intTable = tables.firstWhere((e) => e.dslName == 'IntTable');

    expect(
      stringTable.existingRowClass,
      isA<ExistingRowClass>()
          .having((e) => e.targetClass.name, 'targetClass.name', 'GenericRow')
          .having(
            (e) => e.typeInstantiation,
            'typeInstantiation',
            allOf(
              hasLength(1),
              anyElement(
                isA<DartType>().having(
                    (e) => e.isDartCoreString, 'isDartCoreString', isTrue),
              ),
            ),
          ),
    );

    expect(
      intTable.existingRowClass,
      isA<ExistingRowClass>()
          .having((e) => e.targetClass.name, 'targetClass.name', 'GenericRow')
          .having(
            (e) => e.typeInstantiation,
            'typeInstantiation',
            allOf(
              hasLength(1),
              anyElement(
                isA<DartType>()
                    .having((e) => e.isDartCoreInt, 'isDartCoreInt', isTrue),
              ),
            ),
          ),
    );
  });
}
