
## Using this
For general notes on using drift, see [this guide](https://drift.simonbinder.eu/getting-started/).

To use drift_postgre, add this to pubspec.yaml
```yaml
dependencies:
  drift: "$latest version"
  dift_postgres:
   git:
    url: https://github.com/simolus3/moor.git
    path: extras/dirft_postgres
```

To use this, create connection with `PgDatabase`, import `package:drift_postgres/postgres.dart`.
