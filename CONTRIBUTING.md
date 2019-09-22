# Contributing

Thanks for taking the time to contribute to moor!

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

If you have any question about moor internals that you feel are not explained well enough,
you're most welcome to create an issue or [chat via gitter](http://gitter.im/simolus3).

## Project structure
The project is divided into multiple modules:

- `moor/`: Contains common APIs that will run on all platforms.
  - `backends`: Common helper classes to make implementing backends easier. The idea is that a
  backend only needs to know how to run prepared statements. This lets us port the library to
  different database libraries without much trouble.
  - `moor_web`: Experimental web implementation, built with `sql.js`.
  - This is the biggest module, see the concepts section below on how moor works and what it
    contains.
- `moor_flutter/`: Contains a Flutter implementation for the database.
- `moor_generator/`: Creates table, database and dao classes from the table structure and
   compiled queries.
- `sqlparser/`: Contains an sql parser and analyzer that is fairly independent of moor,
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
A `DatabaseConnectionUser` is the central piece of a moor database instance. It contains an `SqlTypeSystem` (responsible
for mapping simple Dart objects from and to sql), the `QueryExecutor` discussed above and a `StreamQueryStore` 
(responsible for keeping active queries and re-running them when a table updates). It is also the super class of
`GeneratedDatabase` and `DatabaseAccessor`, which are the classes a `@UseMoor` and `@UseDao` class inherits from.
Finally, the `QueryEngine` is a mixin in `DatabaseConnectionUser` that provides the `select`, `update`, `delete` methods
used to construct common queries.

## Workflows

### Releasing to pub
Minor changes will be published directly, no special steps are necessary. For major
updates that span multiple versions, we should follow these steps

1. Changelogs: For new updates, we use the same `CHANGELOG` for `moor` and `moor_flutter`. This
   is because most changes happen with moor directly, but users are most likely depending on the
   Flutter version only. The changelog for the generator should only point out relevant changes to
   the generator.
2. Make sure each package has the correct dependencies: `moor_flutter` version `1.x` should depend
   on moor `1.x` as well to ensure users will always `pub get` moor packages that are compatible
   with each other.
3. Comment out the `dependency_overrides` section in `moor`, `moor/tool/analyzer_plugin`, `moor_flutter`,
   `moor_generator` and `sqlparser`.
4. Publish packages in this order to avoid scoring penalties caused by versions not existing:
   1. `moor`
   2. `moor_generator`
   3. `moor_flutter`
 
The `sqlparser` library can be published independently from moor.

### Building the documentation
We use hugo and docsy to build the documentation. The [readme](docs/README.md) contains everything
you need to know go get started.