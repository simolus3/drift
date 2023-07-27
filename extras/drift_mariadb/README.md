An experimental mariadb backend for Drift.

## Using this

For general notes on using drift, see [this guide](https://drift.simonbinder.eu/getting-started/).

To use drift_mariadb, add this to your `pubspec.yaml`
```yaml
dependencies:
  drift: "$latest version"
  drift_mariadb:
   git:
    url: https://github.com/simolus3/drift.git
    path: extras/drift_mariadb
```

To connect your drift database class to mariadb, use a `MariaDBDatabase` from `package:drift_mariadb/mariadb.dart`.

## Testing

To test this package, first run

```
docker run -p 3306:3306 -e MARIADB_ROOT_PASSWORD=password -e MARIADB_DATABASE=database mariadb:latest
```

It can then be tested with `dart test`.
