import 'package:moor_ffi/database.dart';

const _createTable = r''' 
CREATE TABLE frameworks (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL
);
''';

void main() async {
  final db = await IsolateDb.openMemory();
  await db.execute(_createTable);

  final insertStmt =
      await db.prepare('INSERT INTO frameworks(name) VALUES (?)');
  await insertStmt.execute(['Flutter']);
  await insertStmt.execute(['AngularDart']);
  await insertStmt.close();

  final selectStmt = await db.prepare('SELECT * FROM frameworks ORDER BY name');
  final result = await selectStmt.select();
  for (var row in result) {
    print('${row['id']}: ${row['name']}');
  }

  await selectStmt.close();
  await db.close();
}
