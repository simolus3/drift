---
data:
  title: Expressions
  description: Deep-dive into what kind of SQL expressions can be written in Dart
  weight: 5

# used to be in the "getting started" section
path: docs/getting-started/expressions/
template: layouts/docs/single
---

Expressions are pieces of sql that return a value when the database interprets them.
The Dart API from drift allows you to write most expressions in Dart and then convert
them to sql. Expressions are used in all kinds of situations. For instance, `where`
expects an expression that returns a boolean.

In most cases, you're writing an expression that combines other expressions. Any
column name is a valid expression, so for most `where` clauses you'll be writing
a expression that wraps a column name in some kind of comparison.

{% assign snippets = 'package:drift_docs/snippets/dart_api/expressions.dart.excerpt.json' | readString | json_decode %}

## Comparisons
Every expression can be compared to a value by using `equals`. If you want to compare
an expression to another expression, you can use `equalsExpr`. For numeric and datetime
expressions, you can also use a variety of methods like `isSmallerThan`, `isSmallerOrEqual`
and so on to compare them:
```dart
// find all animals with less than 5 legs:
(select(animals)..where((a) => a.amountOfLegs.isSmallerThanValue(5))).get();

// find all animals who's average livespan is shorter than their amount of legs (poor flies)
(select(animals)..where((a) => a.averageLivespan.isSmallerThan(a.amountOfLegs)));

Future<List<Animal>> findAnimalsByLegs(int legCount) {
  return (select(animals)..where((a) => a.legs.equals(legCount))).get();
}
```

## Boolean algebra
You can nest boolean expressions by using the `&`, `|` operators and the `not` method
exposed by drift:

```dart
// find all animals that aren't mammals and have 4 legs
select(animals)..where((a) => a.isMammal.not() & a.amountOfLegs.equals(4));

// find all animals that are mammals or have 2 legs
select(animals)..where((a) => a.isMammal | a.amountOfLegs.equals(2));
```

If you have a list of predicates for which one or all need to match, you can use
`Expression.or` and `Expression.and`, respectively:

```dart
Expression.and([
  a.isMammal,
  a.amountOfLegs().equals(4),
])
```

## Arithmetic

For `int` and `double` expressions, you can use the `+`, `-`, `*` and `/` operators. To
run calculations between a sql expression and a Dart value, wrap it in a `Variable`:
```dart
Future<List<Product>> canBeBought(int amount, int price) {
  return (select(products)..where((p) {
    final totalPrice = p.price * Variable(amount);
    return totalPrice.isSmallerOrEqualValue(price);
  })).get();
}
```

String expressions define a `+` operator as well. Just like you would expect, it performs
a concatenation in sql.

For integer values, you can use `~`, `bitwiseAnd` and `bitwiseOr` to perform
bitwise operations:

{% include "blocks/snippet" snippets = snippets name = 'bitwise' %}

## Nullability
To check whether an expression evaluates to `NULL` in sql, you can use the `isNull` extension:

```dart
final withoutCategories = select(todos)..where((row) => row.category.isNull());
```

The expression returned will resolve to `true` if the inner expression resolves to null
and `false` otherwise.
As you would expect, `isNotNull` works the other way around.

To use a fallback value when an expression evaluates to `null`, you can use the `coalesce`
function. It takes a list of expressions and evaluates to the first one that isn't `null`:

```dart
final category = coalesce([todos.category, const Constant(1)]);
```

This corresponds to the `??` operator in Dart.

## Date and Time

For columns and expressions that return a `DateTime`, you can use the
`year`, `month`, `day`, `hour`, `minute` and `second` getters to extract individual
fields from that date:

{% include "blocks/snippet" snippets = snippets name = 'date1' %}

The individual fields like `year`, `month` and so on are expressions themselves. This means
that you can use operators and comparisons on them.
To obtain the current date or the current time as an expression, use the `currentDate`
and `currentDateAndTime` constants provided by drift.

You can also use the `+` and `-` operators to add or subtract a duration from a time column:

{% include "blocks/snippet" snippets = snippets name = 'date2' %}

For more complex transformations of a datetime, the `modify` and `modifyAll` function is useful.
For instance, this increments every `dueDate` value for todo items to the same time on a Monday:

{% include "blocks/snippet" snippets = snippets name = 'date3' %}

## `IN` and `NOT IN`
You can check whether an expression is in a list of values by using the `isIn` and `isNotIn`
methods:
```dart
select(animals)..where((a) => a.amountOfLegs.isIn([3, 7, 4, 2]);
```

Again, the `isNotIn` function works the other way around.

## Aggregate functions (like count and sum) {#aggregate}

[Aggregate functions](https://www.sqlite.org/lang_aggfunc.html) are available
from the Dart api. Unlike regular functions, aggregate functions operate on multiple rows at
once.
By default, they combine all rows that would be returned by the select statement into a single value.
You can also make them run over different groups in the result by using
[group by]({{ "select.md#group-by" | pageUrl }}).

### Comparing

You can use the `min` and `max` methods on numeric and datetime expressions. They return the smallest
or largest value in the result set, respectively.

### Arithmetic

The `avg`, `sum` and `total` methods are available. For instance, you could watch the average length of
a todo item with this query:
```dart
Stream<double> averageItemLength() {
  final avgLength = todos.content.length.avg();

  final query = selectOnly(todos)
    ..addColumns([avgLength]);

  return query.map((row) => row.read(avgLength)).watchSingle();
}
```

__Note__: We're using `selectOnly` instead of `select` because we're not interested in any colum that
`todos` provides - we only care about the average length. More details are available
[here]({{ "select.md#group-by" | pageUrl }})

### Counting

Sometimes, it's useful to count how many rows are present in a group. By using the
[table layout from the example]({{ "../setup.md" | pageUrl }}), this
query will report how many todo entries are associated to each category:

```dart
final amountOfTodos = todos.id.count();

final query = db.select(categories).join([
  innerJoin(
    todos,
    todos.category.equalsExp(categories.id),
    useColumns: false,
  )
]);
query
  ..addColumns([amountOfTodos])
  ..groupBy([categories.id]);
```

If you don't want to count duplicate values, you can use `count(distinct: true)`.
Sometimes, you only need to count values that match a condition. For that, you can
use the `filter` parameter on `count`.
To count all rows (instead of a single value), you can use the top-level `countAll()`
function.

More information on how to write aggregate queries with drift's Dart api is available
[here]({{ "select.md#group-by" | pageUrl }})

### group_concat

The `groupConcat` function can be used to join multiple values into a single string:

```dart
Stream<String> allTodoContent() {
  final allContent = todos.content.groupConcat();
  final query = selectOnly(todos)..addColumns(allContent);

  return query.map((row) => row.read(query)).watchSingle();
}
```

The separator defaults to a comma without surrounding whitespace, but it can be changed
with the `separator` argument on `groupConcat`.

## Mathematical functions and regexp

When using a `NativeDatabase`, a basic set of trigonometric functions will be available.
It also defines the `REGEXP` function, which allows you to use `a REGEXP b` in sql queries.
For more information, see the [list of functions]({{ "../Platforms/vm.md#moor-only-functions" | pageUrl }}) here.

## Subqueries

Drift has basic support for subqueries in expressions.

### Scalar subqueries

A _scalar subquery_ is a select statement that returns exactly one row with exactly one column.
Since it returns exactly one value, it can be used in another query:

```dart
Future<List<Todo>> findTodosInCategory(String description) async {
  final groupId = selectOnly(categories)
    ..addColumns([categories.id])
    ..where(categories.description.equals(description));

  return select(todos)..where((row) => row.category.equalsExp(subqueryExpression(groupId)));
}
```

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

{% include "blocks/snippet" snippets = snippets name = 'emptyCategories' %}

### Full subqueries

Drift also supports subqueries that appear in `JOIN`s, which are described in the
[documentation for joins]({{ 'select.md#subqueries' | pageUrl }}).

## Custom expressions
If you want to inline custom sql into Dart queries, you can use a `CustomExpression` class.
It takes a `sql` parameter that lets you write custom expressions:
```dart
const inactive = CustomExpression<bool, BoolType>("julianday('now') - julianday(last_login) > 60");
select(users)..where((u) => inactive);
```

_Note_: It's easy to write invalid queries by using `CustomExpressions` too much. If you feel like
you need to use them because a feature you use is not available in drift, consider creating an issue
to let us know. If you just prefer sql, you could also take a look at
[compiled sql]({{ "../SQL API/custom_queries.md" | pageUrl }}) which is typesafe to use.
