---
title: Expressions
description: Deep-dive into what kind of SQL expressions can be written in Dart
---

Expressions are pieces of SQL that return a value when the database interprets them.
Drift allows you to write most expressions in Dart and then convert
them to SQL. Expressions are used in all kinds of situations. For instance, `where`
expects an expression that returns a boolean.

In most cases, you're writing an expression that combines other expressions. Any
column name is a valid expression, so for most `where` clauses you'll be writing
a expression that wraps a column name in some kind of comparison.

## Comparisons
Every expression can be compared to a value by using `equals`. If you want to compare
an expression to another expression, you can use `equalsExpr`. For numeric and datetime
expressions, you can also use a variety of methods like `isSmallerThan`, `isSmallerOrEqual`
and so on to compare them:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="comparison" />

## Boolean algebra
You can nest boolean expressions by using the `&`, `|` operators and the `not` method
exposed by drift:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="boolean" />

If you have a list of predicates for which one or all need to match, you can use
`Expression.or` and `Expression.and`, respectively:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="listand" />

## Arithmetic

For `int` and `double` expressions, you can use the `+`, `-`, `*` and `/` operators. To
run calculations between an SQL expression and a Dart value, wrap it in a `Variable`:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="arithmetic" />

String expressions define a `+` operator as well. Just like you would expect, it performs
a concatenation in SQL.

For integer values, you can use `~`, `bitwiseAnd` and `bitwiseOr` to perform
bitwise operations:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="bitwise" />

### BigInt

While SQLite and the Dart VM use 64-bit integers, Dart applications compiled to JavaScript
don't.
So, [to represent large integer results](tables.md#when-to-use-bigint-and-int64) when compiling
to the web, you may want to cast an expression to a `BigInt`.

Using `dartCast<BigInt>()` will ensure that the result is interpreted as a `BigInt` by drift.
This doesn't change the generated SQL, drift uses a 64-bit integer type for all databases.

**Example:**
For an expression `(table.columnA * table.columnB).dartCast<BigInt>()`, drift will report the resulting value as a `BigInt` even if `columnA` and `columnB` were defined as regular integers.

## Null checks
To check whether an expression evaluates to `NULL` in SQL, you can use the `isNull` extension:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="nullCheck" />

The expression returned will resolve to `true` if the inner expression resolves to null
and `false` otherwise.
As you would expect, `isNotNull` works the other way around.

To use a fallback value when an expression evaluates to `null`, you can use the `coalesce`
function. It takes a list of expressions and evaluates to the first one that isn't `null`:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="coalesce" />

This corresponds to the `??` operator in Dart.

## Date and Time

For columns and expressions that return a `DateTime`, you can use the
`year`, `month`, `day`, `hour`, `minute` and `second` getters to extract individual
fields from that date:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="date1" />

The individual fields like `year`, `month` and so on are expressions themselves. This means
that you can use operators and comparisons on them.
To obtain the current date or the current time as an expression, use the `currentDate`
and `currentDateAndTime` constants provided by drift.

You can also use the `+` and `-` operators to add or subtract a duration from a time column:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="date2" />

For more complex transformations of a datetime, the `modify` and `modifyAll` function is useful.
For instance, this increments every `dueDate` value for todo items to the same time on a Monday:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="date3" />

## `IN` and `NOT IN`
You can check whether an expression is in a list of values by using the `isIn` and `isNotIn`
methods:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="isIn" />

Again, the `isNotIn` function works the other way around.

## JSON

Support for common JSON operators is provided through `package:drift/extensions/json1.dart`.
This provides things like `jsonExtract` to extract fields from JSON or `jsonEach` to query
nested JSON structures. For more details, see the [JSON support](select.md#json-support) section on the page about selects or [this more complex example](../examples/relationships.md#with-json-functions).

## Aggregate functions (like count and sum)

[Aggregate functions](https://www.sqlite.org/lang_aggfunc.html) are available
from the Dart api. Unlike regular functions, aggregate functions operate on multiple rows at
once.
By default, they combine all rows that would be returned by the select statement into a single value.
You can also make them run over different groups in the result by using
[group by](select.md#group-by).

### Comparing

You can use the `min` and `max` methods on numeric and datetime expressions. They return the smallest
or largest value in the result set, respectively.

### Arithmetic

The `avg`, `sum` and `total` methods are available. For instance, you could watch the average length of
a todo item with this query:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="averageItemLength" />

__Note__: We're using `selectOnly` instead of `select` because we're not interested in any colum that
`todos` provides - we only care about the average length. More details are available
[here](select.md#group-by).

### Counting

Sometimes, it's useful to count how many rows are present in a group. By using the
[table layout from the example](../setup.md), this
query will report how many todo entries are associated to each category:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="counting" />

If you don't want to count duplicate values, you can use `count(distinct: true)`.
Sometimes, you only need to count values that match a condition. For that, you can
use the `filter` parameter on `count`.
To count all rows (instead of a single value), you can use the top-level `countAll()`
function.

More information on how to write aggregate queries with drift's Dart api is available
[here](select.md#group-by)

### group_concat

The `groupConcat` function can be used to join multiple values into a single string:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="allTodoContent" />

The separator defaults to a comma without surrounding whitespace, but it can be changed
with the `separator` argument on `groupConcat`.

### Window functions

In addition to aggregate expressions and `groupBy`, drift supports [window functions](https://en.wikipedia.org/wiki/Window_function_(SQL)).
Unlike regular aggregates, which collapse a group of rows into a single value, window functions allow
running aggregations over a subset of rows related to the current one.
For instance, you could use this to track a running total of values:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="window" />

An interesting use for window function is to determine the rank a row would have if rows were
sorted by some column (without actually returning all rows, or sorting them by that column).
This ranking can be attached to each row:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="window2" />

## Mathematical functions and regexp

When using a `NativeDatabase`, a basic set of trigonometric functions will be available.
It also defines the `REGEXP` function, which allows you to use `a REGEXP b` in SQL queries.
For more information, see the [list of functions](../platforms/vm.md#drift-only-functions) here.

## Subqueries

Drift has basic support for subqueries in expressions.

### Scalar subqueries

A _scalar subquery_ is a select statement that returns exactly one row with exactly one column.
Since it returns exactly one value, it can be used in another query:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="findTodosInCategory" />

Here, `groupId` is a regular select statement. By default drift would select all columns, so we use
`selectOnly` to only load the id of the category we care about.
Then, we can use `subqueryExpression` to embed that query into an expression that we're using as
a filter.

### `isInQuery`

Similar to [`isIn` and `isNotIn`](#in-and-not-in) functions, you can use `isInQuery` to pass
a subquery instead of a direct set of values.

The subquery must return exactly one column, but it is allowed to return more than one row.
`isInQuery` returns true if that value is present in the query.

### Exists

The `existsQuery` and `notExistsQuery` functions can be used to check if a subquery contains
any rows. For instance, we could use this to find empty categories:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="emptyCategories" />

### Full subqueries

Drift also supports subqueries that appear in `JOIN`s, which are described in the
[documentation for joins](select.md#subqueries).

## Custom expressions

If you want to inline custom SQL into Dart queries, you can use a `CustomExpression` class.
It takes an `sql` parameter that lets you write custom expressions:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="custom" />

_Note_: It's easy to write invalid queries by using `CustomExpressions` too much. If you feel like
you need to use them because a feature you use is not available in drift, consider creating an issue
to let us know. If you just prefer SQL, you could also take a look at
[compiled SQL](../sql_api/custom_queries.md) which is type-safe to use.

Especially when custom expressions need to embed sub-expressions, `CustomExpression` is a bit limiting.
A more complex alternative that gives you full control on how snippets are written to SQL can be to
implement `Expression` directly.
For instance, this is an expression that implements [row values](https://sqlite.org/rowvalue.html) with
Drift's query builder:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="row-values" />

It can then be used like this:

<Snippet href="/lib/src/snippets/dart_api/expressions.dart" name="rowvalue-use" />
