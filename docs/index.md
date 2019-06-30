---
layout: home
title: Home
description: Moor is an easy to use, reactive persistence library for Flutter apps.
nav_order: 0
---

# Moor
{: .fs-9 }

Moor is an easy to use, reactive persistence library for Flutter apps. Define your
database tables in pure Dart and enjoy a fluent query API, auto-updating streams
and more!
{: .fs-6 .fw-300 }

[![Build Status](https://travis-ci.com/simolus3/moor.svg?token=u4VnFEE5xnWVvkE6QsqL&branch=master)](https://travis-ci.com/simolus3/moor)
[![codecov](https://codecov.io/gh/simolus3/moor/branch/master/graph/badge.svg)](https://codecov.io/gh/simolus3/moor)

[Get started now]({{ site.common_links.getting_started | absolute_url }}){: .btn .btn-green .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub]({{site.github_link}}){: .btn .btn-outline .fs-5 .mb-4 .mb-md-0 .mr-2 }

---

# Features
Moor contains a whole set of features that makes working with persistence much easier and safer.

## Declarative tables
With moor, you can declare your tables in pure dart without having to miss out on advanced sqlite
features. Moor will take care of writing the `CREATE TABLE` statements when the database is created.

## Fluent queries
Thanks to the power of Dart build system, moor will let you write typesafe queries:
```dart
Future<User> userById(int id) {
    return (select(users)..where((user) => user.id.equals(id))).getSingle();
    // runs SELECT * FROM users WHERE id = ?, automatically binds the parameter
    // and parses the result row.
}
```
No more hard to debug typos in sql, no more annoying to write mapping code - moor takes
care of all the boring parts.

## Prefer SQL? Moor got you covered
Moor contains a powerful sql parser and analyzer, allowing it to create typesafe APIs for
all your sql queries:
```dart
@UseMoor(
  tables: [Categories],
  queries: {
    'categoryById': 'SELECT * FROM categories WHERE id = :id'
  },
)
class MyDatabase extends _$MyDatabase {
// the _$MyDatabase class will have the categoryById(int id) and watchCategoryById(int id)
// methods that execute the sql and parse its result into a generated class.
```
All queries are validated and analyzed during build-time, so that moor can provide hints
about potential errors quickly and generate efficient mapping code once.

## Auto-updating streams
For all your queries, moor can generate a `Stream` that will automatically emit new results
whenever the underlying data changes. This is first-class feature that perfectly integrates
with custom queries, daos and all the other features. Having an auto-updating single source
of truth makes managing perstistent state much easier!

## And much moor...
Moor also supports transactions, DAOs, powerful helpers for migrations, batched inserts and
many more features that makes writing persistence code much easier.

## Getting started
{% include content/getting_started.md %}

You can ignore the `schemaVersion` at the moment, the important part is that you can
now run your queries with fluent Dart code

## [Writing queries]({{"queries" | absolute_url }})
