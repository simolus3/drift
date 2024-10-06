---

title: "CLI"
description: A set of CLI tools to interact with drift projects

---

!!! note "Experimental"

    The drift cli tool is experimental at the moment. Please report all issues you can find.
    

## Usage

If your app depends on `drift_dev`, you're ready to use the CLI tool.
In this article, we'll use `dart run drift_dev` to start the tool.
The tool should be run from the same folder where you keep your `pubspec.yaml`.

## Analyze

Runs drift's analyzer and linter across all `.drift` files in your project.

```
$ dart run drift_dev analyze

WARNING: For file test/data/tables/tables.drift:
WARNING: line 38, column 28: This table has columns without default values, so defaults can't be used for insert.
   ╷
38 │ defaultConfig: INSERT INTO config DEFAULT VALUES;
   │                            ^^^^^^
   ╵
INFO: Found 1 errors or problems
```

Exits with error code `1` if any error was found.

## Identify databases

This is more of a test command to verify that drift's analyzer is working correctly.
It will identify all databases or daos defined in your project.

```
$ dart run drift_dev identify-databases

Starting to scan in /tmp/example/ ...
INFO: example/example.dart has drift databases or daos: Database
INFO: lib/src/data/database.dart has drift databases or daos: AppDatabase
INFO: test/fake_db.dart has drift databases or daos: TodoDb, SomeDao
```

## Make Migration

TODO

## Schema tools

### Dump for version control

This subcommand expects two paths, a Dart file and a target. The Dart file should contain
exactly one class annotated with `@DriftDatabase`. Running the following command will export
the database schema to json.

```
$ dart run drift_dev schema dump path/to/database.dart schema.json
```

The generated file (`schema.json` in this case) contains information about all

- tables, including detailed information about columns
- triggers
- indices
- `@create`-queries from included drift files
- dependencies thereof

Exporting a schema can be used to generate test code for your schema migrations. For details,
see [the guide]("../Migrations/tests.md").

### Exporting

In some cases, it can be beneficial to export a list of `CREATE` statements that define a
drift database.
The `schema export` command does just that. It takes a path to a Dart source file defining
a drift database as an argument:

```
$ dart run drift_dev schema dump path/to/database.dart
```

It will output all statements that would be run by drift if the database were freshly created,
each statement on its own line.

The optional `--dialect` option on `schema export` can be used to control the target dialect
of the generated statements. It defaults to `sqlite` and experimentally also supports
`postgres` and `mariadb`.
