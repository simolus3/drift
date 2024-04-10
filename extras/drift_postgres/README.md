`package:drift_postgres` extends [drift](https://drift.simonbinder.eu/) to support
talking to PostgreSQL databases by using the `postgres` package.

## Using this

For general notes on using drift, see [this guide](https://drift.simonbinder.eu/getting-started/).
Detailed docs on getting started with `drift_postgres` are available [here](https://drift.simonbinder.eu/docs/platforms/postgres/#setup).

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

Also, consider adding builder options to make drift generate postgres-specific code:

```yaml
# build.yaml
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

## Running tests

To test this package, first run

```
docker run -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres
```

It can then be tested with `dart test -j 1` (concurrency needs to be disabled since tests are using the same database).
