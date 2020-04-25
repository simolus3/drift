---
title: "Expressions"
linkTitle: "Expressions in Dart"
description: Deep-dive into what kind of SQL expressions can be written in Dart
weight: 200

# used to be in the "getting started" section
url: docs/getting-started/expressions/
---

Expressions are pieces of sql that return a value when the database interprets them.
The Dart API from moor allows you to write most expressions in Dart and then convert
them to sql. Expressions are used in all kinds of situations. For instance, `where`
expects an expression that returns a boolean.

In most cases, you're writing an expression that combines other expressions. Any
column name is a valid expression, so for most `where` clauses you'll be writing
a expression that wraps a column name in some kind of comparison.

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
You can nest boolean expressions by using the `&`, `!` operators and the `not` method
exposed by moor:
```dart
// find all animals that aren't mammals and have 4 legs
select(animals)..where((a) => a.isMammal.not() & a.amountOfLegs.equals(4))
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
concatenation in sql.

## Nullability
To check whether an expression returns null, you can use the top-level `isNull` function,
which takes any expression and returns a boolean expression. The expression returned will
resolve to `true` if the inner expression resolves to null and `false` otherwise.
As you would expect, `isNotNull` works the other way around.

## Date and Time
For columns and expressions that return a `DateTime`, you can use the
`year`, `month`, `day`, `hour`, `minute` and `second` getters to extract individual
fields from that date:
```dart
select(users)..where((u) => u.birthDate.year.isLessThan(1950))
```

The individual fields like `year`, `month` and so on are expressions themselves. This means
that you can use operators and comparisons on them.
To obtain the current date or the current time as an expression, use the `currentDate` 
and `currentDateAndTime` constants provided by moor.

You can also use the `+` and `-` operators to add or subtract a duration from a time column:

```dart
final toNextWeek = TasksCompanion.custom(dueDate: tasks.dueDate + Duration(weeks: 1));
update(tasks).write(toNextWeek);
```

## `IN` and `NOT IN`
You can check whether an expression is in a list of values by using the `isIn` and `isNotIn`
methods:
```dart
select(animals)..where((a) => a.amountOfLegs.isIn([3, 7, 4, 2]);
```

Again, the `isNotIn` function works the other way around.

## Aggregate functions (like count and sum) {#aggregate}

Since moor 2.4, [aggregate functions](https://www.sqlite.org/lang_aggfunc.html) are available 
from the Dart api. Unlike regular functions, aggregate functions operate on multiple rows at
once. 
By default, they combine all rows that would be returned by the select statement into a single value.
You can also make them run over different groups in the result by using 
[group by]({{< relref "joins.md#group-by" >}}).

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
[here]({{< relref "joins.md#group-by" >}})

### Counting

Sometimes, it's useful to count how many rows are present in a group. By using the
[table layout from the example]({{<relref "../Getting started/_index.md">}}), this
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

More information on how to write aggregate queries with moor's Dart api is available
[here]({{< relref "joins.md#group-by" >}})

## Mathematical functions and regexp

When using `moor_ffi`, a basic set of trigonometric functions will be available. 
It also defines the `REGEXP` function, which allows you to use `a REGEXP b` in sql queries.
For more information, see the [list of functions]({{< relref "../Other engines/vm.md#moor-only-functions" >}}) here.

## Custom expressions
If you want to inline custom sql into Dart queries, you can use a `CustomExpression` class.
It takes a `sql` parameter that let's you write custom expressions:
```dart
const inactive = CustomExpression<bool, BoolType>("julianday('now') - julianday(last_login) > 60");
select(users)..where((u) => inactive);
```

_Note_: It's easy to write invalid queries by using `CustomExpressions` too much. If you feel like
you need to use them because a feature you use is not available in moor, consider creating an issue
to let us know. If you just prefer sql, you could also take a look at 
[compiled sql]({{< ref "../Using SQL/custom_queries.md" >}}) which is typesafe to use.