---
data:
  title: "Documentation & Guides"
  description: Welcome to drift's documentation. This site shows you what drift can do and how to use it.
template: layouts/docs/list
---

## Welcome to drift

Drift is a reactive persistence library for Dart and Flutter applications. It's built on top
of database libraries like [the sqlite3 package](https://pub.dev/packages/sqlite3), [sqflite](https://pub.dev/packages/sqflite) or [sql.js](https://github.com/sql-js/sql.js/)
and provides additional features, like:

- __Type safety__: Instead of writing sql queries manually and parsing the `List<Map<String, dynamic>>` that they
return, drift turns rows into objects of your choice.
- __Stream queries__: Drift lets you "watch" your queries with zero additional effort. Any query can be turned into
 an auto-updating stream that emits new items when the underlying data changes.
- __Fluent queries__: Drift generates a Dart api that you can use to write queries and automatically get their results.
 Keep an updated list of all users with `select(users).watch()`. That's it! No sql to write, no rows to parse.
- __Typesafe sql__: If you prefer to write sql, that's fine! Drift has an sql parser and analyzer built in. It can parse
  your queries at compile time, figure out what columns they're going to return and generate Dart code to represent your
  rows.
- __Migration utils__: Drift makes writing migrations easier thanks to utility functions like `.createAllTables()`.
 You don't need to manually write your `CREATE TABLE` statements and keep them updated.

And much more! Drift validates data before inserting it, so you can get helpful error messages instead of just an
sql error code. Of course, it supports transactions. And DAOs. And efficient batched insert statements. The list goes on.

## Getting started

To get started with drift, follow the [setup guide]({{ 'setup.md' | pageUrl }}).
It explains everything from setting up the dependencies to writing database classes
and generating code.

It also links a few pages intended for developers getting started with drift, so
that you can explore the areas you're most interested in first.
