---
title: Getting started
description: How to add drift to your app, and immediately benefit from a well-structured database that is easy to access.
---

Drift is a powerful database library for Dart and Flutter applications. To
support its advanced capabilities like type-safe SQL queries, verification of
your database and migrations, it uses a builder and command-line tooling that
runs at compile-time.

This means that the setup involves a little more than just adding a single
dependency to your pubspec. This page explains how to add drift to your project.
Relevant sections on this page are explained in more detail in other pages in the
fundamentals section, so you can get a quick overview of what drift has to offer and
how you can integrate it into your app.

If you get stuck adding drift, or have questions or feedback about the project,
please share that with the community by [starting a discussion on GitHub](https://github.com/simolus3/drift/discussions).
If you want to look at an example app for inspiration, a cross-platform Flutter app using drift is available
[as part of the drift repository](https://github.com/simolus3/drift/tree/develop/examples/app).

## The dependencies

First, let's add drift to your project's `pubspec.yaml`.
In addition to the core drift dependencies (`drift` and `drift_dev` to generate code), we're also
adding a package to open database on the respective platform.


===  "Flutter (sqlite3)"

    ```yaml
    dependencies:
      drift: ^{{ versions.drift }}
      drift_flutter: ^0.2.0

    dev_dependencies:
      drift_dev: ^{{ versions.drift_dev }}
      build_runner: ^{{ versions.build_runner }}
    ```

    Alternatively, you can achieve the same result using the following command:

    ```
    dart pub add drift drift_flutter dev:drift_dev dev:build_runner
    ```

    Please note that `drift_flutter` depends on `sqlite3_flutter_libs`, which includes a compiled
    copy of sqlite3 in your app. On Android, that package will include sqlite3 for the following
    architectures: `armv8`, `armv7`, `x86` and `x86_64`.
    Most Flutter apps don't run on 32-bit x86 devices without further setup, so you should
    [add a snippet](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3_flutter_libs#included-platforms)
    to your `build.gradle` if you don't need `x86` builds.
    Otherwise, the Play Store might allow users on `x86` devices to install your app even though it is not
    supported.
    In Flutter's current native build system, drift unfortunately can't do that for you.

===  "Dart (sqlite3)"

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

===  "Dart (Postgres)"

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
    #              - sqlite
    ```

## Tables

!!! info ""

    A full page on this topic is available: [Tables]({{ 'tables.md' }})

Drift is a persistence library built on top of relational databases. This means that
the data you intend to store is part of tables, fundamental building blocks for
organizing your database.
Each table stores a specific entity or concept and defines the structure of
stored data.

To have a consistent example to refer to on this website, we use a possible
structure for a todo-list application as a simple example here.
This structure uses two tables: One to store actual entries in the todo lists,
which have a title, contents and a date.
A second table is used to store categories that todo items can be assigned to.

In drift, tables can be defined with Dart classes. To get started, create a
`database.dart` file somewhere under `lib/` with the following content
(of course, you can use any filename that you like):

{{ load_snippet('scaffold','lib/snippets/setup/database.dart.excerpt.json') }}

Don't worry if the structure of these tables is not clear - the page on
[tables]({{ 'tables.md' }}) explain them in more detail.
For now, remember that these classes define the structure of two tables to
use with drift.

??? question "Prefer SQL?"

    If you prefer using `CREATE TABLE` statements to define the structure of your
    tables directly, drift supports that too!
    If you prefer using SQL to define your tables, drift supports that too! You can read all about the [sql_api](sql_api/index.md) here.

## Database class

Every project using drift needs at least one class to access a database. This class references all the
tables you want to use and is the central entry point for drift's code generator.
To get started, define a database class at the end of the existing file containing
the two tables:

{{ load_snippet('before_generation','lib/snippets/setup/database.dart.excerpt.json') }}

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

=== "Flutter (sqlite3)"

    {{ load_snippet('flutter','lib/snippets/setup/database.dart.excerpt.json',indent=4) }}

    Using the `driftDatabase` function from `drift_flutter` automatically applies
    recommended options and stores your database in the application's documents
    directory by default.
    If you need to customize how databases are opened, you can also set the connection
    up manually:

    ??? note "Manual database setup"

        ```dart
        import 'dart:io';
        import 'package:drift/native.dart';
        import 'package:path_provider/path_provider.dart';
        import 'package:path/path.dart' as p;
        import 'package:sqlite3/sqlite3.dart';
        import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

        LazyDatabase _openConnection() {
          // the LazyDatabase util lets us find the right location for the file async.
          return LazyDatabase(() async {
            // put the database file, called db.sqlite here, into the documents folder
            // for your app.
            final dbFolder = await getApplicationDocumentsDirectory();
            final file = File(p.join(dbFolder.path, 'db.sqlite'));

            // Also work around limitations on old Android versions
            if (Platform.isAndroid) {
              await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
            }

            // Make sqlite3 pick a more suitable location for temporary files - the
            // one from the system may be inaccessible due to sandboxing.
            final cachebase = (await getTemporaryDirectory()).path;
            // We can't access /tmp on Android, which sqlite3 would try by default.
            // Explicitly tell it about the correct temporary directory.
            sqlite3.tempDirectory = cachebase;

            return NativeDatabase.createInBackground(file);
          });
        }
        ```

        The Android-specific workarounds are necessary because sqlite3 attempts to use `/tmp` to store
        private data on unix-like systems, which is forbidden on Android. We also use this opportunity
        to work around a problem some older Android devices have with loading custom libraries through
        `dart:ffi`.


=== "Dart (sqlite3)"

    {{ load_snippet('sqlite3','lib/snippets/setup/database.dart.excerpt.json',indent=4) }}


=== "Dart (Postgres)"

    {{ load_snippet('postgres','lib/snippets/setup/database.dart.excerpt.json',indent=4) }}


## Queries

!!! info ""

    A full page on this topic is available: [Queries]({{ 'queries.md' }})

Congratulations! With this setup complete, your project is ready to use drift
to insert rows and select data:

{{ load_snippet('use','lib/snippets/setup/database.dart.excerpt.json') }}

Notice how drift generated fields on the database for each table, allowing
you to compose [queries]({{ 'queries.md' }}).
To hold the result of queries, drift also generates row classes like `TodoItem`
and `TodoItemsCompanion` which are described in [row classes]({{ 'row_classes.md' }}).

## Next steps

This page explained how to add drift to your project, as well as the basic steps
to set it up to store your data.

The rest of this section explains fundamental concepts of drift in more detail:

1. [Tables]({{ 'tables.md' }}) describes how to define database tables in Dart
   and what options and types are available for columns.
2. [Queries]({{ 'queries.md' }}) shows how to run common queries (insertions,
   reads and modifications) on your data.
3. [Transactions]({{ 'transactions.md' }}) are a powerful feature of relational
   databases allowing you to run multiple queries as one unit.
4. And something to keep in mind for later: [Changing schemas]({{ 'migrations.md' }})
   introduces the steps to follow when making changes to your tables.

Once you're familiar with the basics, the [overview here](index.md) shows what
more drift has to offer.
This includes automated tooling to help with database migrations, multi-platform support and more.
