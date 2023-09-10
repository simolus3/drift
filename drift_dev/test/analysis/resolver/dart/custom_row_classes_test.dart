@Tags(['analyzer'])
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  late TestBackend state;

  setUpAll(() {
    state = TestBackend(const {
      'a|lib/invalid_no_unnamed_constructor.dart': '''
import 'package:drift/drift.dart';

class RowClass {
  RowClass.create();
}
@UseRowClass(RowClass)
class TableClass extends Table {}
      ''',
      'a|lib/invalid_no_named_constructor.dart': '''
import 'package:drift/drift.dart';

class RowClass {
  RowClass();
  RowClass.create();
}
@UseRowClass(RowClass, constructor: 'create2')
class TableClass extends Table {}
      ''',
      'a|lib/mismatching_type.dart': '''
import 'package:drift/drift.dart';

class RowClass {
  RowClass(int x);
}
@UseRowClass(RowClass)
class TableClass extends Table {
  TextColumn get x => text()();
}
      ''',
      'a|lib/mismatching_nullability.dart': '''
import 'package:drift/drift.dart';

class RowClass {
  RowClass(int x);
}
@UseRowClass(RowClass)
class TableClass extends Table {
  IntColumn get x => integer().nullable()();
}
      ''',
      'a|lib/mismatching_type_converter.dart': '''
import 'package:drift/drift.dart';

class MyConverter extends TypeConverter<int, String> {
  const MyConverter();

  @override
  int? fromSql(String? fromDb) => throw 'stub';
  @override
  String? toSql(int? value) => throw 'stub';
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
import 'package:drift/drift.dart';

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
      ''',
      'a|lib/blob.dart': '''
// @dart=2.13
import 'package:drift/drift.dart';

@UseRowClass(Cls)
class Tbl extends Table {
  BlobColumn get foo => blob()();
  BlobColumn get bar => blob()();
  BlobColumn get baz => blob()();
}

typedef Bytes = Uint8List;

class Cls {
  Cls(Uint8List foo, List<int> bar, Bytes baz) {}
}
      ''',
      'a|lib/insertable_missing.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(Cls, generateInsertable: true)
class Tbl extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

class Cls {
  final String foo;

  Cls(this.foo, int bar);
}
''',
      'a|lib/insertable_valid.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(Cls, generateInsertable: true)
class Tbl extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

class HasBar {
  final int bar;

  HasBar(this.bar);
}

class Cls extends HasBar {
  final String foo;

  Cls(this.foo, int bar): super(bar);
}
''',
      'a|lib/async_factory.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(MyCustomClass, constructor: 'load')
class Tbl extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

class MyCustomClass {
  static Future<MyCustomClass> load(String foo, int bar) async {
    throw 'stub';
  }
}
''',
      'a|lib/invalid_static_factory.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(MyCustomClass, constructor: 'invalidReturn')
class Tbl extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

@UseRowClass(MyCustomClass, constructor: 'notStatic')
class Tbl2 extends Table {
  TextColumn get foo => text()();
  IntColumn get bar => integer()();
}

class MyCustomClass {
  static String invalidReturn(String foo, int bar) async {
    throw 'stub';
  }

  MyRowClass notStatic() {
    throw 'stub';
  }
}
''',
      'a|lib/custom_parent_class_no_error.dart': '''
import 'package:drift/drift.dart';

abstract class BaseModel extends DataClass {
  abstract final String id;
}

@DataClassName('Company', extending: BaseModel)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
      'a|lib/custom_parent_class_typed_no_error.dart': '''
import 'package:drift/drift.dart';

abstract class BaseModel<T> extends DataClass {
  abstract final String id;
}

@DataClassName('Company', extending: BaseModel)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
      'a|lib/custom_parent_class_no_super.dart': '''
import 'package:drift/drift.dart';

abstract class BaseModel {
  abstract final String id;
}

@DataClassName('Company', extending: BaseModel)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
      'a|lib/custom_parent_class_wrong_super.dart': '''
import 'package:drift/drift.dart';

class Test {
}

abstract class BaseModel extends Test {
  abstract final String id;
}

@DataClassName('Company', extending: BaseModel)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
      'a|lib/custom_parent_class_typed_wrong_type_arg.dart': '''
import 'package:drift/drift.dart';

abstract class BaseModel<T> extends DataClass {
  abstract final String id;
}

@DataClassName('Company', extending: BaseModel<String>)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
      'a|lib/custom_parent_class_two_type_argument.dart': '''
import 'package:drift/drift.dart';

abstract class BaseModel<T, D> extends DataClass {
  abstract final String id;
}

@DataClassName('Company', extending: BaseModel)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
      'a|lib/custom_parent_class_not_class.dart': '''
import 'package:drift/drift.dart';

typedef NotClass = void Function();

@DataClassName('Company', extending: NotClass)
class Companies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().named('name')();
}
''',
    });
  });

  tearDownAll(() => state.dispose);

  group('warns about misuse', () {
    test('when the desired row class does not have an unnamed constructor',
        () async {
      final file =
          await state.analyze('package:a/invalid_no_unnamed_constructor.dart');
      expect(
        file.allErrors,
        [isDriftError(contains('must have an unnamed constructor'))],
      );
    });

    test('when no constructor with the right name exists', () async {
      final file =
          await state.analyze('package:a/invalid_no_named_constructor.dart');
      expect(
        file.allErrors,
        [isDriftError(contains('does not have a constructor named create2'))],
      );
    });

    test('when a parameter has a mismatching type', () async {
      final file = await state.analyze('package:a/mismatching_type.dart');
      expect(
        file.allErrors,
        [isDriftError(contains('Parameter must accept String'))],
      );
    });

    test('when a parameter should be nullable', () async {
      final file =
          await state.analyze('package:a/mismatching_nullability.dart');
      expect(
        file.allErrors,
        [isDriftError('Expected this parameter to be nullable')],
      );
    });

    test('when a parameter has a mismatching type converter', () async {
      final file =
          await state.analyze('package:a/mismatching_type_converter.dart');
      expect(
        file.allErrors,
        [isDriftError('Parameter must accept int')],
      );
    });

    test('when a getter is missing with generateInsertable: true', () async {
      final file = await state.analyze('package:a/insertable_missing.dart');

      expect(
        file.allErrors,
        [isDriftError(contains('but some are missing: bar'))],
      );
    });

    test('for invalid static factories', () async {
      final file = await state.analyze('package:a/invalid_static_factory.dart');

      expect(
        file.allErrors,
        containsAll([
          isDriftError(contains('it needs to be static')).withSpan('notStatic'),
          isDriftError(contains('needs to return an instance of it'))
              .withSpan('invalidReturn'),
        ]),
      );
    });
  });

  test('supports generic row classes', () async {
    final file = await state.analyze('package:a/generic.dart');
    expect(file.allErrors, isEmpty);

    final stringTable = file.analyzedElements
        .singleWhere((e) => e.id.name == 'string_table') as DriftTable;
    final intTable = file.analyzedElements
        .singleWhere((e) => e.id.name == 'int_table') as DriftTable;

    expect(
      stringTable.existingRowClass,
      isA<ExistingRowClass>()
          .having((e) => e.targetClass.toString(), 'targetClass', 'GenericRow')
          .having(
            (e) => e.targetType.toString(),
            'targetType',
            'GenericRow<String>',
          ),
    );
    expect(stringTable.nameOfRowClass, 'GenericRow');

    expect(
      intTable.existingRowClass,
      isA<ExistingRowClass>()
          .having((e) => e.targetClass.toString(), 'targetClass', 'GenericRow')
          .having(
            (e) => e.targetType.toString(),
            'targetType',
            'GenericRow<int>',
          ),
    );
    expect(intTable.nameOfRowClass, 'GenericRow');
  });

  test('handles blob columns', () async {
    final file = await state.analyze('package:a/blob.dart');
    expect(file.allErrors, isEmpty);
  });

  test('considers inheritance when checking expected getters', () async {
    final file = await state.analyze('package:a/insertable_valid.dart');
    expect(file.allErrors, isEmpty);
  });

  test('supports async factories for existing row classes', () async {
    final file = await state.analyze('package:a/async_factory.dart');
    expect(file.allErrors, isEmpty);

    final table = file.analyzedElements.whereType<DriftTable>().single;
    expect(
        table.existingRowClass,
        isA<ExistingRowClass>()
            .having((e) => e.isAsyncFactory, 'isAsyncFactory', isTrue));
  });

  test('handles `ANY` columns', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'row.dart';

CREATE TABLE foo (
  id INTEGER NOT NULL PRIMARY KEY,
  x ANY
) STRICT WITH FooData;
''',
      'a|lib/row.dart': '''
import 'package:drift/drift.dart';

class FooData {
  FooData({required int id, required DriftAny? x});
}
''',
    });

    final file = await backend.analyze('package:a/a.drift');
    backend.expectNoErrors();

    final table = file.analyzedElements.single as DriftTable;
    expect(table.existingRowClass, isA<ExistingRowClass>());
  });

  group('custom data class parent', () {
    test('check valid', () async {
      final file =
          await state.analyze('package:a/custom_parent_class_no_error.dart');
      expect(file.allErrors, isEmpty);

      final table = file.analyzedElements.single as DriftTable;
      expect(table.customParentClass?.toString(), 'BaseModel');
    });

    test('check valid with type argument', () async {
      final file = await state
          .analyze('package:a/custom_parent_class_typed_no_error.dart');
      expect(file.allErrors, isEmpty);
    });

    test('check extends DataClass (no super)', () async {
      final file =
          await state.analyze('package:a/custom_parent_class_no_super.dart');

      expect(
        file.allErrors,
        [
          isDriftError(contains('Parameter `extending` in '
              '@DataClassName must be subtype of DataClass'))
        ],
      );
    });

    test('extends DataClass (wrong super)', () async {
      final file =
          await state.analyze('package:a/custom_parent_class_wrong_super.dart');

      expect(
        file.allErrors,
        [
          isDriftError(contains('Parameter `extending` in '
              '@DataClassName must be subtype of DataClass'))
        ],
      );
    });

    test('wrong type argument in extending', () async {
      final file = await state
          .analyze('package:a/custom_parent_class_typed_wrong_type_arg.dart');

      expect(
        file.allErrors,
        [
          isDriftError(
              contains('Parameter `extending` in @DataClassName can only be '
                  'provided as'))
        ],
      );
    });

    test('two type arguments in parent class', () async {
      final file = await state
          .analyze('package:a/custom_parent_class_two_type_argument.dart');

      expect(
        file.allErrors,
        [
          isDriftError(
              contains('Parameter `extending` in @DataClassName must have zero '
                  'or one type parameter'))
        ],
      );
    });

    test('not a class in extending', () async {
      final file =
          await state.analyze('package:a/custom_parent_class_not_class.dart');

      expect(
        file.allErrors,
        [
          isDriftError(
              contains('Parameter `extending` in @DataClassName must be used '
                  'with a class'))
        ],
      );
    });
  });

  group('records as row types', () {
    test('supported with explicit record', () async {
      final state = TestBackend.inTest(
        {
          'a|lib/a.dart': '''
import 'package:drift/drift.dart';

typedef MyRecord = ({int id, String name, DateTime birthday});

@UseRowClass(MyRecord)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get birthday => dateTime()();
}
''',
        },
        analyzerExperiments: ['records'],
      );

      final file = await state.analyze('package:a/a.dart');
      state.expectNoErrors();

      final table = file.analyzedElements.single as DriftTable;
      expect(
        table.existingRowClass,
        isA<ExistingRowClass>()
            .having((e) => e.isRecord, 'isRecord', isTrue)
            .having((e) => e.targetClass, 'targetClass', isNull)
            .having((e) => e.targetType.toString(), 'targetType',
                '({DateTime birthday, int id, String name})'),
      );
      expect(table.nameOfRowClass, 'User');
    });

    test('supported with implicit record', () async {
      final state = TestBackend.inTest(
        {
          'a|lib/a.dart': '''
import 'package:drift/drift.dart';

@UseRowClass(Record)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get birthday => dateTime()();
}
''',
        },
        analyzerExperiments: ['records'],
      );

      final file = await state.analyze('package:a/a.dart');
      state.expectNoErrors();

      final table = file.analyzedElements.single as DriftTable;
      expect(
        table.existingRowClass,
        isA<ExistingRowClass>()
            .having((e) => e.isRecord, 'isRecord', isTrue)
            .having((e) => e.targetClass, 'targetClass', isNull)
            .having((e) => e.targetType.toString(), 'targetType',
                '({DateTime birthday, int id, String name})'),
      );
      expect(table.nameOfRowClass, 'User');
    }, skip: requireDart('3.0.0-dev'));
  });
}
