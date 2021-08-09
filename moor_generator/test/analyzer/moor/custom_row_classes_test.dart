// @dart=2.9
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:test/scaffolding.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('can use existing row classes in moor files', () async {
    final state = TestState.withContent({
      'a|lib/db.moor': '''
import 'rows.dart';

CREATE TABLE custom_name (
  id INTEGER NOT NULL PRIMARY KEY,
  foo TEXT
) AS MyCustomClass;

CREATE TABLE existing (
  id INTEGER NOT NULL PRIMARY KEY,
  foo TEXT
) WITH ExistingRowClass;

CREATE VIEW existing_view WITH ExistingForView (foo, bar) 
  AS SELECT 1, 2;
      ''',
      'a|lib/rows.dart': '''
class ExistingRowClass {
  ExistingRowClass(int id, String? foo);
}

class ExistingForView {
  ExistingForView(int foo, int bar);
}
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/db.moor');
    expect(file.errors.errors, isEmpty);

    final result = file.currentResult as ParsedMoorFile;
    final customName = result.declaredEntities
        .singleWhere((e) => e.displayName == 'custom_name') as MoorTable;
    final existing = result.declaredEntities
        .singleWhere((e) => e.displayName == 'existing') as MoorTable;
    final existingView = result.declaredEntities
        .singleWhere((e) => e.displayName == 'existing_view') as MoorView;

    expect(customName.dartTypeName, 'MyCustomClass');
    expect(customName.existingRowClass, isNull);

    expect(existing.dartTypeName, 'ExistingRowClass');
    expect(existing.existingRowClass.targetClass.name, 'ExistingRowClass');

    expect(existingView.dartTypeName, 'ExistingForView');
    expect(existingView.existingRowClass.targetClass.name, 'ExistingForView');
  });

  test('can use generic row classes', () async {
    final state = TestState.withContent({
      'a|lib/generic.dart': '''
//@dart=2.13
typedef StringRow = GenericRow<String>;
typedef IntRow = GenericRow<int>;

class GenericRow<T> {
  final T value;
  GenericRow(this.value);
}
      ''',
      'a|lib/generic.moor': '''
import 'generic.dart';

CREATE TABLE moor_strings (
  value TEXT NOT NULL
) WITH StringRow;

CREATE TABLE moor_ints (
  value INT NOT NULL
) WITH IntRow;
      ''',
    });
    addTearDown(state.close);

    final file = await state.analyze('package:a/generic.moor');
    expect(file.errors.errors, isEmpty);

    final tables = (file.currentResult as ParsedMoorFile).declaredTables;
    final strings = tables.singleWhere((e) => e.sqlName == 'moor_strings');
    final ints = tables.singleWhere((e) => e.sqlName == 'moor_ints');

    expect(
      strings.existingRowClass,
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
      ints.existingRowClass,
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
