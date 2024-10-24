---

title: Verified SQL
description: Define your database and queries in SQL without giving up on type-safety.

---

Drift provides a [dart_api](../dart_api/tables.md) to define tables and
to write SQL queries.
Especially when you are already familiar with SQL, it might be easier to define your
tables directly in SQL, with `CREATE TABLE` statements.
Thanks to a powerful SQL parser and analyzer built into drift, you can still run type-safe
SQL queries with support for auto-updating streams and all the other drift features.
The validity of your SQL is checked at build time, with drift generating matching methods
for each table and SQL statement.

## Setup

The basic setup of adding the drift dependencies matches the setup for the dart_apis. It
is described in the [setup page](../setup.md).

What's different is how tables and queries are declared. For SQL to be recognized by drift,
it needs to be put into a `.drift` file. In this example, we use a `.drift` file next to the
database class named `tables.drift`:



{{ load_snippet('(full)','lib/snippets/drift_files/getting_started/tables.drift.excerpt.json') }}

!!! note "On that AS Category"


    Drift will generate Dart classes for your tables, and the name of those
    classes is based on the table name. By default, drift just strips away
    the trailing `s` from your table. That works for most cases, but in some
    (like the `categories` table above), it doesn't. We'd like to have a
    `Category` class (and not `Categorie`) generated, so we tell drift to
    generate a different name with the `AS <name>` declaration at the end.




Integrating drift files into the database simple, they just need to be added to the
`include` parameter of the `@DriftDatabase` annotation. The `tables` parameter can
be omitted here, since there are no Dart-defined tables to be added to the database.



{{ load_snippet('(full)','lib/snippets/drift_files/getting_started/database.dart.excerpt.json') }}

To generate the `database.g.dart` file which contains the `_$AppDb`
superclass, run `dart run build_runner build` on the command
line.

