---
title: "Welcome to Moor"
linkTitle: "Documentation"
weight: 20
menu:
  main:
    weight: 20
description: >
 Welcome to the moor documentation. This site shows you what moor can do and how to use it.
---

## So what's moor?
Moor is a reactive persistence library for Dart and Flutter applications. It's built ontop
of database libraries like [sqflite](https://pub.dev/packages/sqflite) or [sql.js](https://github.com/kripken/sql.js/)
and provides additional featues, like

- __Type safety__: Instead of writing sql queries manually and parsing the `List<Map<String, dynamic>>` that they 
return, moor turns rows into object of your choice.
- __Stream queries__: Moor let's you "watch" your queries with zero additional effort. Any query can be turned into
 an auto-updating stream that emits new items when the underlying data changes.
- __Fluent queries__: Moor generates a Dart api that you can use to write queries and automatically get their results.
 Keep an updated list of all users with `select(users).watch()`. That's it! No sql to write, no rows to parse.
- __Typesafe sql__: If you prefer to write sql, that's fine! Moor has an sql parser and analyzer built in. It can parse
  your queries at compile time, figure out what columns they're going to return and generate Dart code to represent your
  rows.
- __Migration utils__: Moor makes writing migrations easier thanks to utility functions like `.createAllTables()`.
 You don't need to manually write your `CREATE TABLE` statements and keep them updated.

And much more! Moor validates data before inserting it, so you can get helpful error messages instead of just an
sql error code. Of course, it supports transactions. And DAOs. And efficient batched insert statements. The list goes on.

Check out these in-depth articles to learn about moor and how to use its features.