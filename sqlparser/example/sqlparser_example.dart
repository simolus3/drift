import 'package:sqlparser/sqlparser.dart';

// Example that parses a select statement on some tables defined below and
// prints what columns would be returned by that statement.
void main() {
  final engine = SqlEngine()
    ..registerTable(frameworks)
    ..registerTable(languages)
    ..registerTable(frameworkToLanguage);

  final result = engine.analyze('''
SELECT f.* FROM frameworks f
  INNER JOIN uses_language ul ON ul.framework = f.id
  INNER JOIN languages l ON l.id = ul.language
WHERE l.name = 'Dart'
ORDER BY f.name ASC, f.popularity DESC
LIMIT 5 OFFSET 5 * 3
  ''');

  for (var error in result.errors) {
    print(error);
  }

  final select = result.root as SelectStatement;
  final columns = select.resolvedColumns;

  print('the query returns ${columns.length} columns');

  for (var column in columns) {
    final type = result.typeOf(column);
    print('${column.name}, which will be a $type');
  }
}

// declare some tables. I know this is verbose and boring, but it's needed so
// that the analyzer knows what's going on.
final Table frameworks = Table(
  name: 'frameworks',
  resolvedColumns: [
    TableColumn(
      'id',
      const ResolvedType(type: BasicType.int),
    ),
    TableColumn(
      'name',
      const ResolvedType(type: BasicType.text),
    ),
    TableColumn(
      'popularity',
      const ResolvedType(type: BasicType.real),
    ),
  ],
);

final Table languages = Table(
  name: 'languages',
  resolvedColumns: [
    TableColumn(
      'id',
      const ResolvedType(type: BasicType.int),
    ),
    TableColumn(
      'name',
      const ResolvedType(type: BasicType.text),
    ),
  ],
);

final Table frameworkToLanguage = Table(
  name: 'uses_language',
  resolvedColumns: [
    TableColumn(
      'framework',
      const ResolvedType(type: BasicType.int),
    ),
    TableColumn(
      'language',
      const ResolvedType(type: BasicType.int),
    ),
  ],
);
