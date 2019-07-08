## unreleased
- parse `COLLATE` expressions

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