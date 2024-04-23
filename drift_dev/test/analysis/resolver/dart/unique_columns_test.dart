import 'package:drift_dev/src/analysis/results/table.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  final mainUri = Uri.parse('package:a/main.dart');

  test('does not allow autoIncrement() to have a unique constraint', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().autoIncrement().unique()();
}
'''
    });

    final state = await backend.driver.fullyAnalyze(mainUri);

    expect(
      state.allErrors,
      [
        isDriftError('Primary key column cannot have UNIQUE constraint')
            .withSpan(contains('a')),
      ],
    );
  });

  test('does not allow primary key to have a unique constraint', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().unique()();

  @override
  Set<Column> get primaryKey => {a};
}
'''
    });

    final state = await backend.driver.fullyAnalyze(mainUri);
    expect(
      state.allErrors,
      [
        isDriftError('Primary key column cannot have UNIQUE constraint')
            .withSpan(contains('Test'))
      ],
    );
  });

  test(
      'does not allow primary key to have a unique constraint through override',
      () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [{a}];

  @override
  Set<Column> get primaryKey => {a};
}
'''
    });

    final state = await backend.driver.fullyAnalyze(mainUri);
    expect(
      state.allErrors,
      [
        isDriftError(
          'The uniqueKeys override contains the primary key, which is already '
          'unique by default.',
        ).withSpan(contains('Test'))
      ],
    );
  });

  test('warns about duplicate unique declarations', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().unique()();

  @override
  List<Set<Column>> get uniqueKeys => [{a}];
}
'''
    });
    final state = await backend.driver.fullyAnalyze(mainUri);
    expect(
      state.allErrors,
      [
        isDriftError(
          contains('already has a column-level UNIQUE constraint'),
        ).withSpan(contains('Test'))
      ],
    );
  });

  test('parses unique key definitions', () async {
    final backend = await TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().unique()();
  IntColumn get b => integer().unique()();

  @override
  List<Set<Column>> get uniqueKeys => [{a}, {b}, {a, b}];
}
'''
    });

    final state = await backend.driver.fullyAnalyze(mainUri);
    backend.expectNoErrors();

    final table = state.analyzedElements.whereType<DriftTable>().single;
    final uniqueKeys =
        table.tableConstraints.whereType<UniqueColumns>().toList();

    expect(uniqueKeys, hasLength(3));
    expect(uniqueKeys[0].uniqueSet.map((e) => e.nameInSql), ['a']);
    expect(uniqueKeys[1].uniqueSet.map((e) => e.nameInSql), ['b']);
    expect(uniqueKeys[2].uniqueSet.map((e) => e.nameInSql), ['a', 'b']);
  });
}
