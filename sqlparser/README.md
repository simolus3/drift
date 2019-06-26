# sqlparser

An sql parser and static analyzer, written in pure Dart. Currently in development.

## Using this library

```dart
import 'package:sqlparser/sqlparser.dart';

final engine = SqlEngine();
final stmt = engine.parse('''
SELECT f.* FROM frameworks f
  INNER JOIN uses_language ul ON ul.framework = f.id
  INNER JOIN languages l ON l.id = ul.language
WHERE l.name = 'Dart'
ORDER BY f.name ASC, f.popularity DESC
LIMIT 5 OFFSET 5 * 3
  ''');
// ???
profit();
```

## Features
Not all features are available yet, put parsing select statements (even complex ones!) and
performing analysis on them works!

### AST Parsing
Can parse the abstract syntax tree of any sqlite statement with `SqlEngine.parse`.

### Static analysis

Given information about all tables and a sql statement, this library can:

1. determine which result rows a query is going to have
2. Determine the static type of variables included in the query
3. issue some basic warnings on queries that are syntactically valid but won't run
