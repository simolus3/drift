## 0.18.1

- Fix the AST comparator missing errors for different amount of children.

## 0.18.0

- Fix unecessary errors around `fts5` tables
- Merge all moor-specific nodes into a single `visitMoorSpecific` visitor method
- Parse `BEGIN` and `COMMIT` statements
- Improve type inference around `RETURNING` clauses.

## 0.17.2

- Fix nullability analysis of `COALESCE` and `IFNULL`

## 0.17.1

- Fix nullability analysis of references and star columns

## 0.17.0

- Refactor how tables and columns are resolved in statements
 - The new `ResultSetAvailableInStatement` class describes a result set that
   has been added to a statement, for instance through a from clause
 - A `TableOrSubquery` with an alias now introduces a `TableAlias` instead of
   the original table

## 0.16.0

- New analysis checks for `RETURNING`: Disallow `table.*` syntax and aggregate expressions
- Support `RAISE` expressions in triggers
- Fix resolving columns when `RETURNING` is used in an `UPDATE FROM` statement
- Fix aliases to rowid being reported as nullable

## 0.15.0

- __Breaking__: Change `InsertStatement.upsert` to a list of upsert clauses
    - Support multiple upsert clauses
    - Do not require a conflict target in the last clause
- Support `RETURNING` clauses in updates, deletes and inserts
- Support `FROM` clauses in `UPDATE` statements
- Support `MATERIALIZED`/`NOT MATERIALIZED` hints in common table expressions
- Add `BuiltInMathExtension` which corresponds to the `-DSQLITE_ENABLE_MATH_FUNCTIONS`
  compile-time option for sqlite.
- Add `EngineOptions.version` argument to specify the desired sqlite version. Using newer features will be reported as
  analysis warnings.
- Fix `rank` columns of fts5 tables being misreported as integers

## 0.14.0

- Fix views using common table expressions

## 0.13.0-nullsafety.0

- Parse ordering in table key constraints
    - Deprecate `KeyClause.indexedColumns` in favor of `KeyClause.columns`

## 0.12.0-nullsafety.0

- Migrate to null-safety
- Remove legacy type inference
- Parser support for new moor features

## 0.11.0

- New `package:sqlparser/utils/node_to_text.dart` library that turns an AST node back into a textual representation.
- Fix precedence of `CASE` expressions

## 0.10.1

- Scan identifiers with `[bracket syntax]`
- `NumericToken` now contains individual lexemes making up the number
- Improve error messages in some scenarios
- Fix type inference for binary expressions where the operands have incompatible types
- Improve type inference around `NULL`

## 0.10.0

- Breaking: Made `RecursiveVisitor.visit`, `visitList` and `visitExcept` an extension on `AstVisitor`.
- Support the transformer pattern to modify ast nodes
- Breaking: `FrameBoundary`, `DeleteTarget`, `UpdateTarget`, `DefaultValues` and `InsertTarget` are no longer constant
- Breaking: Removed `visitQueryable`. Use `defaultQueryable` instead.
- Support parsing and analyzing `CREATE VIEW` statements (see `SchemaFromCreateTable.readView`). Thanks
  to [@mqus](https://github.com/mqus) for their contribution!
- `SqlEngine.parse` will no longer throw when there's a parsing error (use `ParseResult.errors` instead).
- Parse `DEFERRABLE` clauses on foreign key constraints
- Parse `NULLS FIRST` and `NULLS LAST` on `ORDER BY` terms

## 0.9.0

- New `package:sqlparser/utils/find_referenced_tables.dart` library. Use it to easily find all referenced tables in a
  query.
- Support [row values](https://www.sqlite.org/rowvalue.html) including warnings about misuse

## 0.8.1

- Support collate expressions in the new type inference ([#533](htt ps://github.com/simolus3/moor/issues/533))
- Added `visitCollateExpression` to the visitor classes

## 0.8.0

- Remove `SqlEngine.withOptions` constructor - the default constructor now takes options
- Changed `SelectStatement.from` from `List<Queryable>` to `Queryable?`. Selecting from multiple tables with a comma
  will now be parsed as a `JoinClause`.
- Changed `SelectStatementAsSource.statement` from `SelectStatement` to `BaseSelectStatement` and allow compound select
  statements to appear in a `FROM` clause
- Support the `VALUES` clause as select statement
- The new type inference engine is now enabled by default and the `enableExperimentalTypeInference` option has been
  removed. To continue using the old engine, the `useLegacyTypeInference` flag can be used.

## 0.7.0

- New feature: Table valued functions.
- __Breaking__: Removed the `enableJson1` parameter on `EngineOptions`. Add a `Json1Extension` instance
  to `enabledExtensions` instead.
- Parse `rowid` as a valid reference when needed (`SELECT rowid FROM tbl` is now parsed correctly)
- Parse `CURRENT_TIME`, `CURRENT_DATE` and `CURRENT_TIMESTAMP`
- Parse `UPSERT` clauses for insert statements

## 0.6.0

- __Breaking:__ Added an argument type and argument to the visitor classes
- Experimental new type inference algorithm
  (`SqlEngine.withOptions(EngineOptions(enableExperimentalTypeInference: true))`)
- Support `CAST` expressions and the `ISNULL` / `NOTNULL` postfixes
- Support parsing `CREATE TRIGGER` statements
- Support parsing `CREATE INDEX` statements

## 0.5.0

- Optionally support the `json1` module
- Optionally support the `fts5` module

## 0.4.0

- Support common table expressions
- Handle special `rowid`, `oid`, `__rowid__` references
- Support references to `sqlite_master` and `sqlite_sequence` tables

## 0.3.0

- parse compound select statements
- scan comment tokens
- experimental auto-complete engine (only supports a tiny subset based on the grammar only)
- some features that are specific to moor

__0.3.0+1__: Accept `\r` characters as whitespace

## 0.2.0

- Parse `CREATE TABLE` statements
- Extract schema information from parsed create table statements with `SchemaFromCreateTable`.

## 0.1.2

- parse `COLLATE` expressions
- fix wrong order in parsed `LIMIT` clauses

## 0.1.1

Attempt to recognize when a bound variable should be an array (eg. in `WHERE x IN ?`). Also fixes a number of parsing
bugs:

- Parses tuples, proper type resolution for `IN` expressions
- Don't resolve references to tables that don't appear in the surrounding statement.
- Parse joins without any additional operator, e.g. `table1 JOIN table2` instead of
  `table1 CROSS JOIN table2`.
- Parser now complains when parsing a query doesn't fully consume the input

## 0.1.0

Initial version, can parse most statements but not `DELETE`, common table expressions and other advanced features.