---
title: Setup
description: All you need to know about adding drift to your project.
---

Drift is a powerful database library for Dart and Flutter applications. To
support its advanced capabilities like type-safe SQL queries, verification of
your database and migrations, it uses a builder and command-line tooling that
runs at compile-time.

This means that the setup involves a little more than just adding a single
dependency to your pubspec. This page explains how to add drift to your project
and gives pointers to the next steps.
If you're stuck adding drift, or have questions or feedback about the project,
please share that with the community by [starting a discussion on GitHub](https://github.com/simolus3/drift/discussions).
If you want to look at an example app for inspiration, a cross-platform Flutter app using drift is available
[as part of the drift repository](https://github.com/simolus3/drift/tree/develop/examples/app).

## The dependencies

First, let's add drift to your project's `pubspec.yaml`.
In addition to the core drift dependencies (`drift` and `drift_dev` to generate code), we're also
adding a package to open databases on the respective platform.

<Tabs defaultValue="sqlite3">
  <TabItem label="Flutter (sqlite3)" value="sqlite3_flutter">

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  drift_flutter: ^{{ versions.drift_flutter }}
  path_provider: ^{{ versions.path_provider }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

Alternatively, you can achieve the same result using the following command:

```shell
dart pub add drift drift_flutter path_provider dev:drift_dev dev:build_runner
```

</TabItem>
<TabItem label="Dart (sqlite3)" value="sqlite3">

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  sqlite3: ^{{ versions.sqlite3 }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

Alternatively, you can achieve the same result using the following command:

```
dart pub add drift sqlite3 dev:drift_dev dev:build_runner
```

</TabItem>
<TabItem label="Dart (postgres)" value="postgres">

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  postgres: ^{{ versions.postgres }}
  drift_postgres: ^{{ versions.drift_postgres }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

Alternatively, you can achieve the same result using the following command:

```
dart pub add drift postgres drift_postgres dev:drift_dev dev:build_runner
```

Drift only generates code for sqlite3 by default. So, also create a `build.yaml`
to [configure](generation_options/index.md) `drift_dev`:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialects:
              - postgres
              # Uncomment if you need to support both
    #         - sqlite
```

</TabItem>
</Tabs>

## Database class

Every project using drift needs at least one class to access a database. This class references all the
tables you want to use and is the central entry point for drift's code generator.
In this example, we'll assume that this database class is defined in a file called `database.dart` and
somewhere under `lib/`. Of course, you can put this class in any Dart file you like.

To make the database useful, we'll also add a simple table to it. This table, `TodoItems`, can be used
to store todo items for a todo list app.
Everything there is to know about defining tables in Dart is described on the [Dart tables](dart_api/tables.md) page.
If you prefer using SQL to define your tables, drift supports that too! You can read all about that
[here](sql_api/index.md).

For now, populate the contents of `database.dart` with these tables which could form the persistence
layer of a simple todolist application:

<Snippet href="/lib/src/snippets/setup/database.dart" name="before_generation" />

You will get an analyzer warning on the `part` statement and on `extends _$AppDatabase`. This is
expected because drift's generator did not run yet.
You can do that by invoking [build_runner](https://pub.dev/packages/build_runner):

 - `dart run build_runner build` generates all the required code once.
 - `dart run build_runner watch` watches for changes in your sources and generates code with
   incremental rebuilds. This is suitable for development sessions.

After running either command, the `database.g.dart` file containing the generated `_$AppDatabase`
class will have been generated.
You will now see errors related to missing overrides and a missing constructor. The constructor
is responsible for telling drift how to open the database. The `schemaVersion` getter is relevant
for migrations after changing the database, we can leave it at `1` for now. Update `database.dart`
so it now looks like this:

<a name="open"></a>

<Tabs defaultValue="sqlite3">
  <TabItem label="Flutter (sqlite3)" value="sqlite3_flutter">

<Snippet href="/lib/src/snippets/setup/database.dart" name="flutter" />

If you need to customize how databases are opened, you can also set the connection
up manually:

<Collapsible title="Manual database setup">
<Snippet href="/lib/src/snippets/setup/custom_flutter_setup.dart" name="custom" />

The Android-specific workarounds are necessary because sqlite3 attempts to use `/tmp` to store
private data on unix-like systems, which is forbidden on Android. We also use this opportunity
to work around a problem some older Android devices have with loading custom libraries through
`dart:ffi`.

</Collapsible>

</TabItem>
<TabItem label="Dart (sqlite3)" value="sqlite3">

<Snippet href="/lib/src/snippets/setup/database.dart" name="sqlite3" />

</TabItem>
<TabItem label="Dart (postgres)" value="postgres">

<Snippet href="/lib/src/snippets/setup/database.dart" name="postgres" />

</TabItem>
</Tabs>



## Next steps

Congratulations! With this setup complete, your project is ready to use drift.
This short snippet shows how the database can be opened and how to run inserts and selects:

<Snippet href="/lib/src/snippets/setup/database.dart" name="use" />

But drift can do so much more! These pages provide more information useful when getting
started with drift:

- [Dart tables](dart_api/tables.md): This page describes how to define your own tables in Dart.
  For an overview of the classes drift generates for tables, check out [row classes](dart_api/rows.md).
- For new drift users or users not familiar with SQL, the [manager](dart_api/manager.md) APIs
  for tables allows writing most queries with a syntax you're likely familiar with from ORMs or other
  packages.
- Writing queries: Drift-generated classes support writing the most common SQL statements, like
  [selects](dart_api/select.md) or [inserts, updates and deletes](dart_api/writes.md).
- Something to keep in mind for later: When changing the database, for instance by adding new columns
  or tables, you need to write a migration so that existing databases are transformed to the new
  format. Drift's extensive [migration tools](migrations/index.md) help with that.
- Take a look at our [FAQ](./faq.md)! It will help you with the most common questions about drift projects.

Once you're familiar with the basics, the [overview here](index.md) shows what
more drift has to offer.
This includes transactions, automated tooling to help with migrations, multi-platform support
and more.
