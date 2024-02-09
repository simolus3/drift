## 1.2.0

- Drift's comparable expression operators are now available for expressions
  using postgres-specific `date` or `timestamp` types.

## 1.1.0

- Add `PgTypes.timestampWithTimezone`.

## 1.0.0

- __Breaking__: The interval type now expects `Interval` types from postgres
  instead of `Duration` objects.
- Migrate to the stable v3 version of the `postgres` package.

## 0.1.0

- Initial release of `drift_postgres`.
