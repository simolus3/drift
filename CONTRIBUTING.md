# Contributing

Thanks for taking the time to contribute to drift!

## Reporting issues

Feel free to post any questions, bug reports or feature requests by creating an issue.
In any case, taking the time to provide some context on
- what you were trying to do
- what you would have expected to happen
- what actually happened

most certainly helps to resolve the issue quickly.

## Contributing code
All kinds of pull requests are absolutely appreciated! Before working on bigger changes, it
can be helpful to create an issue describing your plans to help coordination.

When working on drift, its recommended to fork the `develop` branch and also target that
branch for PRs. When possible, we only use the `latest_release` branch to reflect the state
that's been released to pub.

If you have any question about drift internals that you feel are not explained well enough,
you're most welcome to create an issue.

## Project structure

The project is divided into multiple modules:

- `drift/`: Contains common APIs that will run on all platforms.
  - `backends`: Common helper classes to make implementing backends easier. The idea is that a
  backend only needs to know how to run prepared statements. This lets us port the library to
  different database libraries without much trouble.
  - `web.dart`: Experimental web implementation, built with `sql.js`.
  - `native.dart`: FFI-based implementation around the `sqlite3` package.
  - This is the biggest package, see the concepts section below on how drift works and what it
    contains.
- `drift_flutter/`: Utility functions to open databases, with reasonable defaults for Flutter apps.
- `drift_dev/`: Creates table, database and dao classes from the table structure and
   compiled queries.
- `sqlparser/`: Contains an SQL parser and analyzer that is mostly independent of drift,
  but used by the generator for compiled custom queries.

## Concepts

For each user-defined class that inherits from `Table` and appears in a `@DriftDatabase` or `@DriftAccessor`
annotation, we generate three classes:

1. A class that inherits from `TableInfo` (we call this the "table class"). It contains a structural representation
   of the table, which includes columns (including name, type, constraints...), the primary key and so on. The idea is
   that, if we have a `TableInfo` instance, we can create all kinds of SQL statements.
2. A class to represent a fully loaded row of a table. We call this a "data class" and it inherits from `DataClass`.
3. A "companion" class to represent partial data (e.g. for inserts or updates, where not all columns are set).

This approach lets us write a higher-level api that uses the generated `TableInfo` classes to know what columns to
write. For instance, the `Migrator` can write `CREATE TABLE` statements from these classes, an `UpdateStatement` will
write `UPDATE` statements and so on. To write the query, we construct a `GenerationContext`, which contains a string
buffer to write the query, keeps track of the introduced variables and so on. The idea is that everything that can
appear anywhere in an SQL statement inherits from `Component` (for instance, `Query`, `Expression`, `Variable`, `Where`,
`OrderBy`). We can then recursively create the query by calling `Component.writeInto` for all subparts of a component.
This query is then sent to a `QueryExecutor`, which is responsible for executing it and returning its result. The
`QueryExecutor` is the only part that is platform specific, everything else is pure Dart that doesn't import any
restricted libraries.

### Important classes

A `DatabaseConnectionUser` is the central piece of a drift database instance. It contains an `SqlTypes` instance
(responsible for mapping simple Dart objects from and to SQL), the `QueryExecutor` discussed above and a `StreamQueryStore`
(responsible for keeping active queries and re-running them when a table updates). It is also the super class of
`GeneratedDatabase` and `DatabaseAccessor`, which are the classes a `@DriftDatabase` class inherits from.
Finally, `DatabaseConnectionUser` also provides the `select`, `update`, `delete` methods used to construct common
statements.

## Workflows

### Debugging the builder

To debug the builder in a real build, run this in the `drift` subdirectory
(or any other directory you want to use as an input):

```
dart run build_runner build --force-jit --dart-jit-vm-arg "--observe" --dart-jit-vm-arg "--pause-isolates-on-start"
```

This prints a message on startup that can be used to attach a debugger.

### Releasing to pub

Minor changes will be published directly, no special steps are necessary. For major
updates that span multiple versions, we should follow these steps

1. Changelogs: The changelog of `drift_dev` should only mention changes to the generator,
   most changes shuold be in `drift/CHANGELOG.md`.
2. Make sure each package has the correct dependencies: `drift_dev` version `1.x` should depend
   on `drift` `1.x` as well to ensure users will always `dart pub get` drift packages that are compatible
   with each other.
3. Create an annotated tag and a GitHub release for each package published. `drift` and `drift_dev` can be
   merged into a single GitHub release. This will automatically release them to pub.dev.

The `sqlparser` library can be published independently of drift.

### Building the documentation

We use `build_runner` to build the documentation. The [readme](docs/README.md) contains everything
you need to know go get started.
