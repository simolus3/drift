import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart';
import 'package:test/test.dart';

void main() {
  SqlEngine engine;
  const schemaReader = SchemaFromCreateTable();
  Table users, logins;

  setUpAll(() {
    engine = SqlEngine();

    Table addTableFromStmt(String create) {
      final parsed = engine.parse(create);
      final table = schemaReader.read(parsed.rootNode as CreateTableStatement);

      engine.registerTable(table);
      return table;
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
  });

  test('recognizes read tables', () {
    final ctx = engine.analyze('SELECT * FROM logins INNER JOIN users u '
        'ON u.id = logins.user;');
    expect(findReferencedTables(ctx.root), {users, logins});
  });

  test('resolves aliased tables', () {
    final ctx = engine.analyze('''
      CREATE TRIGGER foo AFTER INSERT ON users BEGIN
        INSERT INTO logins (user, timestamp) VALUES (new.id, 0);
      END;
    ''');
    final body = (ctx.root as CreateTriggerStatement).action;

    // Users referenced via "new" in body.
    expect(findReferencedTables(body), contains(users));
  });

  test('recognizes written tables', () {
    final ctx = engine.analyze('INSERT INTO logins '
        'SELECT id, CURRENT_TIME FROM users;');
    expect(
        findWrittenTables(ctx.root), {TableWrite(logins, UpdateKind.insert)});
  });
}
