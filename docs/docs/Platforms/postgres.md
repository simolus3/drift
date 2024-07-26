---

title: PostgreSQL support
description: Use drift with PostgreSQL database servers.

---

While drift has originally been designed as a client-side database wrapper for SQLite databases, it can also be used
with PostgreSQL database servers.
Without having to change your query code, drift can generate Postgres-compatible SQL for most queries.
Please keep in mind that some drift APIs, like those for date time modification, are only supported with SQLite.
Most queries will work without any modification though.

## Setup

Begin by adding both `drift` and `drift_postgres` to your pubspec:



```yaml
dependencies:
  drift: ^{{ versions.drift }}
  drift_postgres: ^{{ versions.drift_postgres }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

Defining a database with Postgres is no different than defining it for sqlite3 - the
pages on [Dart](../setup.md) and [SQL](../SQL API/index.md)
explain how to define tables picked up by drift.

Different dialects require changes in generated code in some cases. Since most drift users are
targeting sqlite3, drift generates code optimized for sqlite3 by default. To enable code generation
for PostgreSQL as well, [create a `build.yaml`](../Generation options/index.md) next to your pubspec with this content:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialects:
              - sqlite # remove this line if you only need postgres
              - postgres
```



Then, perhaps this example database is helpful as a starting point:

{{ load_snippet('(full)','lib/snippets/platforms/postgres.dart.excerpt.json') }}

After starting a database server, for example by running `docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres`,
you can run the example to see drift talking to Postgres.

## API extensions

The postgres library provides a few [custom types](../SQL API/types.md) enabling you to use
postgres-specific types when writing queries in drift.
For instance, the `PgTypes.uuid` type used in the example maps to a native UUID column type in Postgres. The
`gen_random_uuid()` function in postgres is also exposed.

PostgreSQL provides a much larger set of functions, of which currently only a few are exported in the
`drift_postgres` package. You can call others with a `FunctionCallExpression` - if you do, contributions extending
`drift_postgres` are always welcome!

## Migrations

In sqlite3, the current schema version is stored in the database file. To support drift's migration API
being built ontop of this mechanism in Postgres as well, drift creates a `__schema` table storing
the current schema version.

This migration mechanism works for simple deployments, but is unsuitable for large database setups
with many application servers connecting to postgres. For those, an existing migration management
tool is a more reliable alternative. If you chose to manage migrations with another tool, you can
disable migrations in postgres by passing `enableMigrations: false` to the `PgDatabase` constructor.

## Current state

Drift's support for PostgreSQL is stable in the sense that the current API is unlikely to break.
Still, it is a newer implementation and integration tests for PostgreSQL are less extensive than
the tests for SQLite databases. And while drift offers typed wrappers around most functions supported
by SQLite, only a tiny subset of PostgreSQL's advanced operators and functions are exposed by
`drift_postgres`.

If you're running into problems or bugs with the postgres database, please let us know by creating an issue
or a discussion.
Contributions expanding wrappers around PosgreSQL functions are also much appreciated.
