import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';
import 'package:test/test.dart';

void main() {
  late SqlEngine engine;
  const schemaReader = SchemaFromCreateTable();
  late Table users, logins;
  late View oldUsers;

  setUpAll(() {
    engine = SqlEngine();

    Table addTableFromStmt(String create) {
      final parsed = engine.parse(create);
      final table = schemaReader.read(parsed.rootNode as CreateTableStatement);

      engine.registerTable(table);
      return table;
    }

    View addViewFromStmt(String create) {
      final result = engine.analyze(create);
      final view =
          schemaReader.readView(result, result.root as CreateViewStatement);

      engine.registerView(view);
      return view;
    }

    users = addTableFromStmt('''
      CREATE TABLE users (
        id INTEGER NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
      );
    ''');

    logins = addTableFromStmt('''
      CREATE TABLE logins (
        user INTEGER NOT NULL REFERENCES users (id),
        timestamp INT
      );
    ''');

    oldUsers = addViewFromStmt('''
      CREATE VIEW old_users AS
        SELECT u.* FROM users u
          WHERE (SELECT MAX(timestamp) FROM logins WHERE user = u.id) < 10000;
    ''');
  });

  test('recognizes read tables', () {
    final ctx = engine.analyze('SELECT * FROM logins INNER JOIN users u '
        'ON u.id = logins.user;');
    expect(findReferencedTables(ctx.root), {users, logins});
  });

  test('finds views', () {
    final ctx = engine.analyze('SELECT * FROM old_users WHERE id > 10');
    final visitor = ReferencedTablesVisitor()..visit(ctx.root, null);
    expect(visitor.foundViews, {oldUsers});
  });

  test('resolves aliased tables', () {
    final ctx = engine.analyze('''
      CREATE TRIGGER foo AFTER INSERT ON users BEGIN
        INSERT INTO logins (user, timestamp) VALUES (new.id, 0);
      END;
    ''');
    expect(ctx.errors, isEmpty);
    final body = (ctx.root as CreateTriggerStatement).action;

    // Users referenced via "new" in body.
    expect(findReferencedTables(body), contains(users));
  });

  group('recognizes written tables', () {
    test('for insert', () {
      final ctx = engine.analyze('INSERT INTO logins '
          'SELECT id, CURRENT_TIME FROM users;');
      expect(
          findWrittenTables(ctx.root), {TableWrite(logins, UpdateKind.insert)});
    });

    test('for deletes', () {
      final ctx = engine.analyze('DELETE FROM users;');
      expect(
          findWrittenTables(ctx.root), {TableWrite(users, UpdateKind.delete)});
    });
  });

  test('ignores unresolved references', () {
    final ctx = engine.analyze('UPDATE xzy SET foo = bar');

    expect(findWrittenTables(ctx.root), isEmpty);
    expect(ctx.errors, hasLength(3)); // unknown table, two unknown references
  });

  group('find references without analysis', () {
    void testWith(String sql, Set<String> references) {
      final result = engine.parse(sql);
      expect(result.errors, isEmpty);

      final found = engine.findReferencedSchemaTables(result.rootNode);
      expect(found, references,
          reason: 'Query `$sql` references `$references`');
    }

    test('finds references for simple queries', () {
      testWith('SELECT * FROM foo', {'foo'});
      testWith('DELETE FROM bar', {'bar'});
      testWith('VALUES (1, 2, 3)', {});
    });

    test('does not include references resolved in the query', () {
      testWith('WITH foo AS (VALUES(1,2,3)) SELECT * FROM foo', {});
    });

    test('works for complex statements', () {
      testWith('''
CREATE TRIGGER my_trigger BEFORE DELETE on target BEGIN
  SELECT * FROM old;
  SELECT * FROM new; -- note: This is a delete trigger
END
''', {'target', 'new'});

      testWith('''
CREATE TRIGGER my_trigger BEFORE UPDATE on target BEGIN
  SELECT * FROM old;
  SELECT * FROM new;
END
''', {'target'});
    });
  });
}
