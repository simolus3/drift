An experimental postgres backend for Drift.

## Using this

For general notes on using drift, see [this guide](https://drift.simonbinder.eu/getting-started/).

To use drift_postgres, add this to your `pubspec.yaml`
```yaml
dependencies:
  drift: "$latest version"
  drift_postgres:
   git:
    url: https://github.com/simolus3/drift.git
    path: extras/drift_postgres
```

To connect your drift database class to postgres, use a `PgDatabase` from `package:drift_postgres/postgres.dart`.

