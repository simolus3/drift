import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('can use existing row classes in drift files', () async {
    final state = TestBackend.inTest({
      'a|lib/db.drift': '''
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

    final file = await state.analyze('package:a/db.drift');
    state.expectNoErrors();

    final customName =
        file.analysis[file.id('custom_name')]!.result! as DriftTable;
    final existing = file.analysis[file.id('existing')]!.result! as DriftTable;
    final existingView =
        file.analysis[file.id('existing_view')]!.result! as DriftView;

    expect(customName.nameOfRowClass, 'MyCustomClass');
    expect(customName.existingRowClass, isNull);

    expect(existing.nameOfRowClass, 'ExistingRowClass');
    expect(
        existing.existingRowClass!.targetClass.toString(), 'ExistingRowClass');

    expect(existingView.nameOfRowClass, 'ExistingForView');
    expect(existingView.existingRowClass!.targetClass.toString(),
        'ExistingForView');
  });

  test('can use generic row classes', () async {
    final state = TestBackend.inTest({
      'a|lib/generic.dart': '''
//@dart=2.13
typedef StringRow = GenericRow<String>;
typedef IntRow = GenericRow<int>;

class GenericRow<T> {
  final T value;
  GenericRow(this.value);
}
      ''',
      'a|lib/generic.drift': '''
import 'generic.dart';

CREATE TABLE drift_strings (
  value TEXT NOT NULL
) WITH StringRow;

CREATE TABLE drift_ints (
  value INT NOT NULL
) WITH IntRow;
      ''',
    });

    final file = await state.analyze('package:a/generic.drift');
    state.expectNoErrors();

    final strings =
        file.analysis[file.id('drift_strings')]!.result! as DriftTable;
    final ints = file.analysis[file.id('drift_ints')]!.result! as DriftTable;

    expect(
        strings.existingRowClass,
        isA<ExistingRowClass>().having((e) => e.targetType.toString(),
            'targetType', 'GenericRow<String>'));

    expect(
        ints.existingRowClass,
        isA<ExistingRowClass>().having(
            (e) => e.targetType.toString(), 'targetType', 'GenericRow<int>'));
  });
}
