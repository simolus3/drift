## 0.8.1

- Support collate expressions in the new type inference ([#533](https://github.com/simolus3/moor/issues/533))
- Added `visitCollateExpression` to the visitor classes

## 0.8.0

- Remove `SqlEngine.withOptions` constructor - the default constructor now takes options
- Changed `SelectStatement.from` from `List<Queryable>` to `Queryable?`. Selecting from multiple
  tables with a comma will now be parsed as a `JoinClause`.
- Changed `SelectStatementAsSource.statement` from `SelectStatement` to `BaseSelectStatement` and allow
  compound select statements to appear in a `FROM` clause
- Support the `VALUES` clause as select statement
- The new type inference engine is now enabled by default and the `enableExperimentalTypeInference` option
  has been removed. To continue using the old engine, the `useLegacyTypeInference` flag can be used.

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
Attempt to recognize when a bound variable should be an array (eg. in `WHERE x IN ?`).
Also fixes a number of parsing bugs:
- Parses tuples, proper type resolution for `IN` expressions
- Don't resolve references to tables that don't appear in the surrounding statement.
- Parse joins without any additional operator, e.g. `table1 JOIN table2` instead of 
`table1 CROSS JOIN table2`.
- Parser now complains when parsing a query doesn't fully consume the input

## 0.1.0
Initial version, can parse most statements but not `DELETE`, common table expressions and other
advanced features.