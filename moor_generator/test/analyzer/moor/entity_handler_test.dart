import 'package:moor_generator/moor_generator.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('finds referenced tables', () {
    const definitions = {
      'foo|lib/b.moor': '''
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR
);
'''
    };

    TestState state;

    tearDown(() => state?.close());

    test('in a foreign key clause', () async {
      state = TestState.withContent(const {
        'foo|lib/a.moor': '''
import 'b.moor';

CREATE TABLE friendships (
  user_a INTEGER REFERENCES users (id),
  user_b INTEGER REFERENCES users (id),
  
  PRIMARY KEY(user_a, user_b),
  CHECK (user_a != user_b)
);
         ''',
        ...definitions,
      });

      final file = await state.analyze('package:foo/a.moor');
      expect(file.errors.errors, isEmpty);

      final table = file.currentResult.declaredTables.single;
      expect(
        table.references,
        [
          const TypeMatcher<MoorTable>()
              .having((table) => table.displayName, 'displayName', 'users'),
        ],
      );
    });

    test('in a trigger', () async {
      state = TestState.withContent(const {
        'foo|lib/a.moor': '''
import 'b.moor';

CREATE TABLE friendships (
  user_a INTEGER REFERENCES users (id),
  user_b INTEGER REFERENCES users (id),
  
  PRIMARY KEY(user_a, user_b),
  CHECK (user_a != user_b)
);

CREATE TRIGGER my_trigger AFTER DELETE ON users BEGIN
  DELETE FROM friendships WHERE user_a = old.id OR user_b = old.id;
END;
        ''',
        ...definitions,
      });

      final file = await state.analyze('package:foo/a.moor');
      expect(file.errors.errors, isEmpty);

      final trigger =
          file.currentResult.declaredEntities.whereType<MoorTrigger>().single;
      expect(
        trigger.references,
        {
          const TypeMatcher<MoorTable>().having(
              (table) => table.displayName, 'displayName', 'friendships'),
          const TypeMatcher<MoorTable>()
              .having((table) => table.displayName, 'displayName', 'users'),
        },
      );

      expect(trigger.bodyReferences.map((t) => t.sqlName),
          {'users', 'friendships'});
      expect(trigger.bodyUpdates.map((t) => t.table.sqlName), {'friendships'});
    });

    test('in an index', () async {
      state = TestState.withContent(const {
        'foo|lib/a.moor': '''
import 'b.moor';

CREATE INDEX idx ON users (name);
        ''',
        ...definitions,
      });

      final file = await state.analyze('package:foo/a.moor');
      expect(file.errors.errors, isEmpty);

      final trigger = file.currentResult.declaredEntities.single as MoorIndex;
      expect(trigger.references, {
        const TypeMatcher<MoorTable>()
            .having((table) => table.displayName, 'displayName', 'users'),
      });
    });
  });

  group('issues error when referencing an unknown table', () {
    TestState state;

    tearDown(() => state?.close());

    test('in a foreign key clause', () async {
      state = TestState.withContent(const {
        'foo|lib/a.moor': '''
CREATE TABLE foo (
  id INTEGER NOT NULL REFERENCES bar (baz) PRIMARY KEY
);
        '''
      });

      final file = await state.analyze('package:foo/a.moor');

      expect(
        file.errors.errors.map((e) => e.message),
        contains('Referenced table bar could not befound.'),
      );
    });

    test('in a trigger', () async {
      state = TestState.withContent(const {
        'foo|lib/a.moor': '''
CREATE TRIGGER IF NOT EXISTS foo BEFORE DELETE ON bar BEGIN
END;
        ''',
      });

      final file = await state.analyze('package:foo/a.moor');

      expect(
        file.errors.errors.map((e) => e.message),
        contains('Target table bar could not be found.'),
      );
    });
  });
}
