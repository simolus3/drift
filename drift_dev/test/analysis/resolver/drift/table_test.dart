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
        await backend.driver.fullyAnalyze(Uri.parse('package:a/a.drift'));

    expect(state, hasNoErrors);
    final results = state.analysis.values.toList();

    final a = results[0].result! as DriftTable;
    final aFoo = a.columns[0];
    final aBar = a.columns[1];

    final b = results[1].result! as DriftTable;
    final bBar = b.columns[0];

    expect(aFoo.sqlType, DriftSqlType.int);
    expect(aFoo.nullable, isFalse);
    expect(aFoo.constraints, isEmpty);
    expect(aFoo.customConstraints, isNull);

    expect(aBar.sqlType, DriftSqlType.int);
    expect(aBar.nullable, isTrue);
    expect(aBar.constraints, [
      isA<ForeignKeyReference>()
          .having((e) => e.otherColumn, 'otherColumn', bBar)
          .having((e) => e.onUpdate, 'onUpdate', isNull)
          .having((e) => e.onDelete, 'onDelete', isNull)
    ]);
    expect(aBar.customConstraints, isNull);

    expect(bBar.sqlType, DriftSqlType.int);
    expect(bBar.nullable, isFalse);
    expect(bBar.constraints, isEmpty);
    expect(bBar.customConstraints, isNull);
  });
}
