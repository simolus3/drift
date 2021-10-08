//@dart=2.9
@Tags(['analyzer'])
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/services/find_stream_update_rules.dart';

import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../analyzer/utils.dart';

void main() {
  test('finds update rules for triggers', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name VARCHAR NOT NULL
);

CREATE TRIGGER add_angry_user
   AFTER INSERT ON users
   WHEN new.name != UPPER(new.name)
BEGIN
  INSERT INTO users (name) VALUES (UPPER(new.name));
END;
      ''',
      'foo|lib/main.dart': '''
import 'package:moor/moor.dart';

@UseMoor(include: {'a.moor'})
class MyDatabase {}      
      '''
    });

    final file = await state.analyze('package:foo/main.dart');
    state.close();
    final db = (file.currentResult as ParsedDartFile).declaredDatabases.single;

    final rules = FindStreamUpdateRules(db).identifyRules();

    expect(rules.rules, hasLength(1));
    expect(
      rules.rules.single,
      isA<WritePropagation>()
          .having(
              (e) => e.on,
              'on',
              const TableUpdateQuery.onTableName('users',
                  limitUpdateKind: UpdateKind.insert))
          .having((e) => e.result, 'result',
              {const TableUpdate('users', kind: UpdateKind.insert)}),
    );
  });

  test('finds update rules for foreign key constraint', () async {
    final state = TestState.withContent({
      'foo|lib/a.moor': '''
CREATE TABLE a (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  bar TEXT
);

CREATE TABLE will_delete_on_delete (
  col INTEGER NOT NULL REFERENCES a(id) ON DELETE CASCADE
);

CREATE TABLE will_update_on_delete (
  col INTEGER REFERENCES a(id) ON DELETE SET NULL
);

CREATE TABLE unaffected_on_delete (
  col INTEGER REFERENCES a(id) ON DELETE NO ACTION
);

CREATE TABLE will_update_on_update (
  col INTEGER NOT NULL REFERENCES a(id) ON UPDATE CASCADE
);

CREATE TABLE unaffected_on_update (
  col INTEGER NOT NULL REFERENCES a(id) ON UPDATE NO ACTION
);
      ''',
      'foo|lib/main.dart': '''
import 'package:moor/moor.dart';

@UseMoor(include: {'a.moor'})
class MyDatabase {}
      '''
    });

    final file = await state.analyze('package:foo/main.dart');
    state.close();

    final db = (file.currentResult as ParsedDartFile).declaredDatabases.single;

    expect(state.file('package:foo/a.moor').errors.errors, isEmpty);

    final rules = FindStreamUpdateRules(db).identifyRules();

    const updateA =
        TableUpdateQuery.onTableName('a', limitUpdateKind: UpdateKind.update);
    const deleteA =
        TableUpdateQuery.onTableName('a', limitUpdateKind: UpdateKind.delete);

    TableUpdate update(String table) {
      return TableUpdate(table, kind: UpdateKind.update);
    }

    TableUpdate delete(String table) {
      return TableUpdate(table, kind: UpdateKind.delete);
    }

    Matcher writePropagation(TableUpdateQuery cause, TableUpdate effect) {
      return isA<WritePropagation>()
          .having((e) => e.on, 'on', cause)
          .having((e) => e.result, 'result', equals([effect]));
    }

    expect(
      rules.rules,
      containsAll(
        [
          writePropagation(
            deleteA,
            delete('will_delete_on_delete'),
          ),
          writePropagation(
            deleteA,
            update('will_update_on_delete'),
          ),
          writePropagation(
            updateA,
            update('will_update_on_update'),
          ),
        ],
      ),
    );
    expect(rules.rules, hasLength(3));
  });
}
