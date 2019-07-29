import 'package:moor_generator/src/parser/moor/moor_analyzer.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:test_api/test_api.dart';

void main() {
  final content = '''
CREATE TABLE users(
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL CHECK(LENGTH(name) BETWEEN 5 AND 30)
);
  ''';

  test('extracts table structure from .moor files', () async {
    final analyzer = MoorAnalyzer(content);
    final result = await analyzer.analyze();

    expect(result.errors, isEmpty);

    final table =
        result.parsedFile.declaredTables.single.extractTable(TypeMapper());

    expect(table.sqlName, 'users');
  });
}
