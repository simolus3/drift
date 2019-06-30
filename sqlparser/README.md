# sqlparser

An sql parser and static analyzer, written in pure Dart. At the moment, only `SELECT` and `DELETE`
statements are supported. Further, this library only targets the sqlite dialect at the time being.

## Features
Not all features are available yet, put parsing select statements (even complex ones!) and
performing analysis on them works!

### Just parsing
You can parse the abstract syntax tree of sqlite statements with `SqlEngine.parse`.
```dart
import 'package:sqlparser/sqlparser.dart';

final engine = SqlEngine();
final result = engine.parse('''
SELECT f.* FROM frameworks f
  INNER JOIN uses_language ul ON ul.framework = f.id
  INNER JOIN languages l ON l.id = ul.language
WHERE l.name = 'Dart'
ORDER BY f.name ASC, f.popularity DESC
LIMIT 5 OFFSET 5 * 3
  ''');
// result.rootNode contains the select statement in tree form
```

### Analysis
Given information about all tables and a sql statement, this library can:

1. Determine which result columns a query is going to have, including types and nullability
2. Make an educated guess about what type the variables in the query should have (it's not really
   possible to be 100% accurate about this because sqlite is very flexible at types)
3. Issue warnings about queries that are syntactically valid but won't run

To use the analyzer, first register all known tables via `SqlEngine.registerTable`. Then,
`SqlEngine.analyze(sql)` gives you a `AnalysisContext` which contains an annotated ast and information
about errors. The type of result columns and expressions can be inferred by using 
`AnalysisContext.typeOf()`. Here's an example.

```dart 
final id = TableColumn('id', const ResolvedType(type: BasicType.int));
final content = TableColumn('content', const ResolvedType(type: BasicType.text));
final demoTable = Table(
  name: 'demo',
  resolvedColumns: [id, content],
);
final engine = SqlEngine()..registerTable(demoTable);

final context =
    engine.analyze('SELECT id, d.content, *, 3 + 4 FROM demo AS d');

final select = context.root as SelectStatement;
final resolvedColumns = select.resolvedColumns;

resolvedColumns.map((c) => c.name)); // id, content, id, content, 3 + 4
resolvedColumns.map((c) => context.typeOf(c).type.type) // int, text, int, text, int, int
```

## But why?
[Moor](https://pub.dev/packages/moor_flutter), a persistence library for Flutter apps, uses this
package to generate type-safe methods from sql.

## Limitations
- For now, only `SELECT` and `DELETE` expressions are implemented, `UPDATE` and `INSERT` will follow
  soon.
- Windowing is not supported yet
- Common table expressions and compound select statements `UNION` / `INTERSECT` are not supported
  and probably won't be in the near future.

## Thanks
- To [Bob Nystrom](https://github.com/munificent) for his amazing ["Crafting Interpreters"](https://craftinginterpreters.com/)
  book, which was incredibly helpful when writing the parser.
- To the authors of [SQLDelight](https://github.com/square/sqldelight). This library uses their algorithm
  for type inference.
