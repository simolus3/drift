---
data:
  title: PostgreSQL support (Alpha)
  description: Use drift with PostgreSQL database servers.
  weight: 10
template: layouts/docs/single
---

{% block "blocks/pageinfo" %}
Postgres support is still in development. In particular, drift is waiting for [version 3](https://github.com/isoos/postgresql-dart/issues/105)
of the postgres package to stabilize. Minor breaking changes or remaining issues are not unlikely.
{% endblock %}

Thanks to contributions from the community, drift currently has alpha support for postgres with the `drift_postgres` package.
Without having to change your query code, drift can generate Postgres-compatible SQL for most queries,
allowing you to use your drift databases with a Postgres database server.

## Setup

Begin by adding both `drift` and `drift_postgres` to your pubspec:

{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  drift_postgres: ^{{ versions.drift_postgres }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

Defining a database with Postgres is no different than defining it for sqlite3 - the
pages on [Dart]({{ '../setup.md' | pageUrl }}) and [SQL]({{ '../SQL API/index.md' | pageUrl }})
explain how to define tables picked up by drift.

{% assign snippets = "package:drift_docs/snippets/platforms/postgres.dart.excerpt.json" | readString | json_decode %}

Perhaps this example database is helpful as a starting point:

{% include "blocks/snippet" snippets = snippets name = "(full)" %}

After starting a database server, for example by running `docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres`,
you can run the example to see drift talking to Postgres.

## API extensions

The postgres library provides a few [custom types]({{ '../SQL API/types.md' | pageUrl }}) enabling you to use
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

Drift's support for Postgres is still in development, and the integration tests we have for Postgres are
less extensive than the tests for sqlite3 databases.
Also, some parts of the core APIs (like the datetime expressions API) are direct wrappers around SQL
functions only available in sqlite3 and won't work in Postgres.
However, you can already create tables (or use an existing schema) and most queries should work already.

If you're running into problems or bugs with the postgres database, please let us know by creating an issue
or a discussion.