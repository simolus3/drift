import 'package:sqlparser/sqlparser.dart';

// Example that parses a select statement on some tables defined below and
// prints what columns would be returned by that statement.
void main() {
  final engine = SqlEngine()
    ..registerTableFromSql(
      '''
      CREATE TABLE frameworks (
        id INTEGER NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        popularity REAL NOT NULL
      );
      ''',
    )
    ..registerTableFromSql(
      '''
      CREATE TABLE languages (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
      ''',
    )
    ..registerTableFromSql(
      '''
      CREATE TABLE uses_language (
        framework INTEGER NOT NULL REFERENCES frameworks (id),
        language INTEGER NOT NULL REFERENCES languages (id),
        PRIMARY KEY (framework, language)
      );
      ''',
    );

  // Use SqlEngine.analyze to parse a single sql statement and analyze it.
  // Analysis can be used to find semantic errors, lints and inferred types of
  // expressions or result columns.
  final result = engine.analyze('''
SELECT f.* FROM frameworks f
  INNER JOIN uses_language ul ON ul.framework = f.id
  INNER JOIN languages l ON l.id = ul.language
WHERE l.name = 'Dart'
ORDER BY f.name ASC, f.popularity DESC
LIMIT 5 OFFSET 5 * 3
  ''');

  result.errors.forEach(print);

  final select = result.root as SelectStatement;
  final columns = select.resolvedColumns!;

  print('the query returns ${columns.length} columns');

  for (final column in columns) {
    final type = result.typeOf(column);
    print('${column.name}, which will be a $type');
  }
}

extension on SqlEngine {
  /// Utility function that parses a `CREATE TABLE` statement and registers the
  /// created table to the engine.
  void registerTableFromSql(String createTable) {
    final stmt = parse(createTable).rootNode as CreateTableStatement;
    registerTable(schemaReader.read(stmt));
  }
}
