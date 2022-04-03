import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('does not allow autoIncrement() to have a unique constraint', () async {
    final state = TestState.withContent({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().autoIncrement().unique()();
}
'''
    });
    addTearDown(state.close);

    (await state.analyze('package:a/main.dart')).expectDartError(
        'Primary key column cannot have UNIQUE constraint', 'a');
  });

  test('does not allow primary key to have a unique constraint', () async {
    final state = TestState.withContent({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().unique()();

  @override
  Set<Column> get primaryKey => {a};
}
'''
    });
    addTearDown(state.close);

    (await state.analyze('package:a/main.dart')).expectDartError(
        'Primary key column cannot have UNIQUE constraint', 'Test');
  });

  test(
      'does not allow primary key to have a unique constraint through override',
      () async {
    final state = TestState.withContent({
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
    addTearDown(state.close);

    (await state.analyze('package:a/main.dart')).expectDartError(
        'The uniqueKeys override contains the primary key, which is already '
            'unique by default.',
        'Test');
  });

  test('warns about duplicate unique declarations', () async {
    final state = TestState.withContent({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class Test extends Table {
  IntColumn get a => integer().unique()();

  @override
  List<Set<Column>> get uniqueKeys => [{a}];
}
'''
    });
    addTearDown(state.close);

    (await state.analyze('package:a/main.dart')).expectDartError(
        contains('already has a column-level UNIQUE constraint'), 'Test');
  });

  test('parses unique key definitions', () async {
    final state = TestState.withContent({
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
    addTearDown(state.close);

    final file = await state.analyze('package:a/main.dart');
    expect(file.errors.errors, isEmpty);

    final table = file.currentResult!.declaredTables.single;
    expect(table.uniqueKeys, hasLength(3));
    expect(table.uniqueKeys![0].map((e) => e.name.name), ['a']);
    expect(table.uniqueKeys![1].map((e) => e.name.name), ['b']);
    expect(table.uniqueKeys![2].map((e) => e.name.name), ['a', 'b']);
  });
}
