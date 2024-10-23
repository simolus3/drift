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
pages on [Dart](../setup.md) and [SQL](../sql_api/index.md)
explain how to define tables picked up by drift.

Different dialects require changes in generated code in some cases. Since most drift users are
targeting sqlite3, drift generates code optimized for sqlite3 by default. To enable code generation
for PostgreSQL as well, [create a `build.yaml`](../generation_options/index.md) next to your pubspec with this content:

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

{{ load_snippet('setup','lib/snippets/platforms/postgres.dart.excerpt.json') }}

After starting a database server, for example by running `docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres`,
you can run the example to see drift talking to Postgres.

## Custom connections and connection pools

The unnamed `PgDatabase` constructor mirrors the options found on the `Endpoint` class in
`package:postgres`, as it uses that class to establish a connection to PostgreSQL.
In some cases, for instance because you already have an existing Postgres connection or because
you need something different from the existing `Endpoint`, you can use `PgDatabase.opened`
with your existing `Session` from `package:postgres`.

This technique is also useful for pooling connections to Postgres, as the `Pool` implementation
from `package:postgres` implements the `Session` interface:

{{ load_snippet('pool','lib/snippets/platforms/postgres.dart.excerpt.json') }}

## API extensions

The postgres library provides a few [custom types](../sql_api/types.md) enabling you to use
postgres-specific types when writing queries in drift.
For instance, the `PgTypes.uuid` type used in the example maps to a native UUID column type in Postgres. The
`gen_random_uuid()` function in postgres is also exposed.

PostgreSQL provides a much larger set of functions, of which currently only a few are exported in the
`drift_postgres` package. You can call others with a `FunctionCallExpression` - if you do, contributions extending
`drift_postgres` are always welcome!

## Avoiding sqlite-specific drift APIs

Early drift versions were designed with SQLite in mind only. Support for PostgreSQL and other database systems
has only been added in more recent versions, and this is reflected by some drift APIs being SQLite-specific.
These will be moved into separate libraries in a future major release to avoid confusion, but it's best to be
aware of them for the time being.
This section lists affected APIs and workarounds to make them work PostgreSQL.

1. Most parts of the `Migrator` API are SQLite-specific. You will be able to create tables on PostgreSQL as well,
   but methods like `alterTable` will only work with SQLite.
   The [migrations](#migrations) section below describes possible workarounds - the recommended approach is to
   export your drift schema and then use dedicated migration tools for PostgreSQL.
2. Drift's datetime columns were designed to work with SQLite, which doesn't have dedicated datetime types.
   Most of the date time APIs (like `currentDateAndTime`) will not work with PostgreSQL.
   When using drift databases with PostgreSQL, we suggest avoiding the default `dateTime()` column type and instead
   use `PgTypes.date` or `PgTypes.datetime`.
   If you need to support both sqlite3 and Postgres, consider using [dialect-aware types](../sql_api/types.md#dialect-awareness).

### Migrations

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
