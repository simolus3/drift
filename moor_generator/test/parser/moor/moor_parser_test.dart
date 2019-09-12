import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:test_api/test_api.dart';

void main() {
  final content = '''
CREATE TABLE users(
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL CHECK(LENGTH(name) BETWEEN 5 AND 30)
);
  ''';

  test('extracts table structure from .moor files', () async {
    final parseStep = ParseMoorStep(null, null, content);
    final result = await parseStep.parseFile();

    expect(parseStep.errors.errors, isEmpty);

    final table = result.declaredTables.single;

    expect(table.sqlName, 'users');
  });
}
