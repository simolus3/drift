# sqlparser

Sql parser and static analyzer written in Dart. At the moment, this library targets the
sqlite dialect only.

## Features

This library aims to support every sqlite feature, which includes parsing and detailed
static analysis.
We can resolve what type a column in a `SELECT` statement has, infer types for variables,
find semantic errors and more.

This library supports most sqlite features:
- DQL: Full support, including joins, `group by`, nested and compound selects, `WITH` clauses
  and window functions
- DDL: Supports `CREATE TABLE` statements, including advanced features like foreign keys or
  virtual tables (when a matching module like `fts5` is enabled). This library also supports
  `CREATE TRIGGER` and `CREATE INDEX` statements.

### Using the parser
To obtain an abstract syntax tree from an sql statement, use `SqlEngine.parse`.
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
   possible to be 100% accurate about this because sqlite is very flexible at types, but this library
   gets it mostly right)
3. Issue basic warnings about queries that are syntactically valid but won't run (references unknown
   tables / columns, uses undefined functions, etc.)

To use the analyzer, first register all known tables via `SqlEngine.registerTable`. Then,
`SqlEngine.analyze(sql)` gives you an `AnalysisContext` which contains an annotated AST and information
about errors. The type of result columns and expressions can be inferred by using 
`AnalysisContext.typeOf()`. Here's an example:

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

resolvedColumns.map((c) => c.name); // id, content, id, content, 3 + 4
resolvedColumns.map((c) => context.typeOf(c).type.type); // int, text, int, text, int, int
```

## But why?
[Moor](https://pub.dev/packages/moor), a persistence library for Dart apps, uses this
package to generate type-safe methods from sql.

## Thanks
- To [Bob Nystrom](https://github.com/munificent) for his amazing ["Crafting Interpreters"](https://craftinginterpreters.com/)
  book, which was incredibly helpful when writing the parser.
