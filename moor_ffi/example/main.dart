import 'package:moor_ffi/database.dart';

const _createTable = r''' 
CREATE TABLE frameworks (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL
);
''';

void main() {
  final db = Database.memory();
  db.execute(_createTable);

  final insertStmt = db.prepare('INSERT INTO frameworks(name) VALUES (?)');
  insertStmt.execute(['Flutter']);
  insertStmt.execute(['AngularDart']);
  insertStmt.close();

  final selectStmt = db.prepare('SELECT * FROM frameworks ORDER BY name');
  final result = selectStmt.select();
  for (var row in result) {
    print('${row['id']}: ${row['name']}');
  }

  selectStmt.close();
  db.close();
}
