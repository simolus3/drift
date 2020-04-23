---
title: "Command line tools for moor"
description: A set of CLI tools to interact with moor files
url: /cli/
---

{{% alert title="Experimental"  %}}
The moor cli tool is experimental at the moment. Please report all issues you can find.
{{% /alert %}}

## Usage

If your app depends on `moor_generator`, you're ready to use the CLI tool.
In this article, we'll use `pub run ...` to start the tool.
If you're using Flutter, you need to run `flutter pub run ...`.
In either case, the tool should be run from the same folder where you keep your
`pubspec.yaml`.

## Analyze

Runs moor's analyzer and linter across all `.moor` files in your project.

```
$ pub run moor_generator analyze

WARNING: For file test/data/tables/tables.moor:
WARNING: line 38, column 28: This table has columns without default values, so defaults can't be used for insert.
   ╷
38 │ defaultConfig: INSERT INTO config DEFAULT VALUES;
   │                            ^^^^^^
   ╵
INFO: Found 1 errors or problems
```

Exits with error code `1` if any error was found.

## Identify databases

This is more of a test command to verify that moor's analyzer is working correctly.
It will identify all databases or daos defined in your project.

```
$ pub run moor_generator identify-databases

Starting to scan in /home/simon/IdeaProjects/moor/moor...
INFO: example/example.dart has moor databases or daos: Database
INFO: lib/src/data/database.dart has moor databases or daos: AppDatabase
INFO: test/fake_db.dart has moor databases or daos: TodoDb, SomeDao
```

## Schema tools

### Export

This subcommand expects two paths, a Dart file and a target. The Dart file should contain
exactly one class annotated with `@UseMoor`. Running the following command will export
the database schema to json.

```
$ pub run moor_generator schema dump path/to/databases.dart schema.json
```

The generated file (`schema.json` in this case) contains information about all

- tables, including detailed information about columns
- triggers
- indices
- `@create`-queries from included moor files
- dependecies thereof

The schema format is still a work-in-progress and might change in the future.
