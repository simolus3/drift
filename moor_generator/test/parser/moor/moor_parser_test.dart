import 'package:moor_generator/src/analyzer/moor/parser.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:test_api/test_api.dart';

void main() {
  final content = '''
CREATE TABLE users(
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL CHECK(LENGTH(name) BETWEEN 5 AND 30)
);
  ''';

  test('extracts table structure from .moor files', () async {
    final task = MoorTask(null, null, content);
    final analyzer = MoorParser(task);
    final result = await analyzer.parseAndAnalyze();

    expect(task.errors.errors, isEmpty);

    final table = result.declaredTables.single;

    expect(table.sqlName, 'users');
  });
}
