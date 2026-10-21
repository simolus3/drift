An experimental mariadb backend for Drift.

Note that the backend is currently experimental and not fully functional yet.

## Using this

For general notes on using drift, see [this guide](https://drift.simonbinder.eu/getting-started/).

To use drift_mariadb, add this to your `pubspec.yaml`

```yaml
dependencies:
  drift3_preview: "$latest version"
  drift_mariadb: ^0.1.0
```

To connect your drift database class to mariadb, use a `mariaDbDriftConnection` from `package:drift_mariadb/drift_mariadb.dart`.

## Testing

To test this package, first run

```
docker run -p 3306:3306 -e MARIADB_ROOT_PASSWORD=password -e MARIADB_DATABASE=database mariadb:latest
```

It can then be tested with `dart test`.
