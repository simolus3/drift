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
you're most welcome to create an issue or [chat via gitter](https://gitter.im/moor-dart/community).

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
- `moor_flutter/`: Contains a Flutter implementation for the database.
- `drift_dev/`: Creates table, database and dao classes from the table structure and
   compiled queries.
- `sqlparser/`: Contains an sql parser and analyzer that is mostly independent of drift,
  but used by the generator for compiled custom queries.

## Concepts
For each user-defined class that inherits from `Table` and appears in a `@UseMoor` or `@UseDao` annotation,
we generate three classes:

1. A class that inherits from `TableInfo` (we call this the "table class"). It contains a structural representation
   of the table, which includes columns (including name, type, constraints...), the primary key and so on. The idea is
   that, if we have a `TableInfo` instance, we can create all kinds of sql statements.
2. A class to represent a fully loaded row of a table. We call this a "data class" and it inherits from `DataClass`.
3. A class to represent partial data (e.g. for inserts or updates, where not all columns are set). This class was
   introduced in moor 1.5 and is called a "companion".

This approach lets us write a higher-level api that uses the generated `TableInfo` classes to know what columns to
write. For instance, the `Migrator` can write `CREATE TABLE` statements from these classes, an `UpdateStatement` will
write `UPDATE` statements and so on. To write the query, we construct a `GenerationContext`, which contains a string
buffer to write the query, keeps track of the introduced variables and so on. The idea is that everything that can
appear anywhere in a sql statement inherits from `Component` (for instance, `Query`, `Expression`, `Variable`, `Where`,
`OrderBy`). We can then recursively create the query by calling `Component.writeInto` for all subparts of a component.
This query is then sent to a `QueryExecutor`, which is responsible for executing it and returning its result. The
`QueryExecutor` is the only part that is platform specific, everything else is pure Dart that doesn't import any
restricted libraries.

### Important classes
A `DatabaseConnectionUser` is the central piece of a drift database instance. It contains an `SqlTypeSystem` (responsible
for mapping simple Dart objects from and to sql), the `QueryExecutor` discussed above and a `StreamQueryStore`
(responsible for keeping active queries and re-running them when a table updates). It is also the super class of
`GeneratedDatabase` and `DatabaseAccessor`, which are the classes a `@UseMoor` and `@UseDao` class inherits from.
Finally, the `QueryEngine` is a mixin in `DatabaseConnectionUser` that provides the `select`, `update`, `delete` methods
used to construct common queries.

## Workflows

### Debugging the analyzer plugin

We have an analyzer plugin to support IDE features like auto-complete, navigation, syntax
highlighting, outline and folding to users. Normally, analyzer plugins are discovered and
loaded by the analysis server, which makes them very annoying to debug.

However, we found a way to run the plugin in isolation, which makes debugging much easier.
Note: Port 9999 has to be free for this to work, but you can change the
port defined in the two files below.

To debug the plugin, do the following:
1. In `drift/tools/analyzer_plugin/bin/plugin.dart`, set `useDebuggingVariant` to true.
2. Run `drift_dev/tool/debug_plugin.dart` as a regular Dart VM app
   (this can be debugged when started from an IDE).
3. (optional) Make sure the analysis server picks up the updated version of the analysis
   plugin by deleting the `~/.dartServer/.plugin_manager` folder.
4. Open a project that uses the plugin, for instance via `code extras/plugin_example`.

More details are available under `extras/plugin_example/README.md`.

### Debugging the builder

To debug the builder, run `pub run build_runner generate-build-script` in the `drift`
subdirectory (or any other directory you want to use as an input). This will generate
a `.dart_tool/build/entrypoint/build.dart`. That file can be run and debugged as a
regular Dart VM app. Be sure to pass something like `build -v` as program arguments
and use the input package as a working directory.

### Releasing to pub
Minor changes will be published directly, no special steps are necessary. For major
updates that span multiple versions, we should follow these steps

1. Changelogs: The changelog of `drift_dev` should only mention changes to the generator,
   most changes shuold be in `drift/CHANGELOG.md`. Generator changes should also be copied
   into that file.
2. Make sure each package has the correct dependencies: `drift_dev` version `1.x` should depend
   on `drift` `1.x` as well to ensure users will always `pub get` drift packages that are compatible
   with each other.
3. Comment out the `dependency_overrides` section in `drift`, `drift/tool/analyzer_plugin`, `moor_flutter`,
   `drift_dev` and `sqlparser`. Make sure that `useDebuggingVariant` is false in the
   analyzer plugin.
4. Create an annotated tag and a GitHub release for each package published. `drift` and `drift_dev` can be
   merged into a single GitHub release.
5. Publish packages in this order to avoid scoring penalties caused by versions not existing:
   1. `drift`
   2. `drift_dev`
   3. (optional) `moor_flutter`

The `sqlparser` library can be published independently from drift.

### Building the documentation

We use `build_runner` to build the documentation. The [readme](docs/README.md) contains everything
you need to know go get started.
