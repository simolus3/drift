`package:drift_postgres` extends [drift](https://drift.simonbinder.eu/) to support
talking to PostgreSQL databases by using the `postgres` package.

This package is currently in beta.

## Using this

For general notes on using drift, see [this guide](https://drift.simonbinder.eu/getting-started/).

To use drift_postgres, add this to your `pubspec.yaml`
```yaml
dependencies:
  drift: "$latest version"
  drift_postgres: ^0.1.0
```

To connect your drift database class to postgres, use a `PgDatabase` from `package:drift_postgres/postgres.dart`:

```dart
final database = AppDatabase(PgDatabase(
  endpoint: PgEndpoint(
    host: 'localhost',
    database: 'postgres',
    username: 'postgres',
    password: 'postgres',
  ),
));
```

## Running tests

To test this package, first run

```
docker run -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres
```

It can then be tested with `dart test`.
