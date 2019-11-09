---
title: "Expressions"
linkTitle: "Expressions"
description: Deep-dive into what kind of SQL expressions can be written in Dart
weight: 200
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

To obtain the current date or the current time as an expression, use the `currentDate` 
and `currentDateAndTime` constants provided by moor.

## `IN` and `NOT IN`
You can check whether an expression is in a list of values by using the `isIn` andd `isNotIn`
method:
```dart
select(animals)..where((a) => a.amountOfLegs.isIn([3, 7, 4, 2]);
```

Again, the `isNotIn` function works the other way around.

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