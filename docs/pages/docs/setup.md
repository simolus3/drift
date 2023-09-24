---
data:
  title: "Setup"
  description: All you need to know about adding drift to your project.
  weight: 1
template: layouts/docs/single
path: /docs/getting-started/
aliases:
  - /getting-started/  # Used to have this url as well
---

{% assign snippets = 'package:drift_docs/snippets/setup/database.dart.excerpt.json' | readString | json_decode %}

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

## The dependencies {#adding-dependencies}

First, lets add drift to your project's `pubspec.yaml`.
In addition to the core drift dependencies, we're also adding packages to find a suitable database
location on the device and to include a recent version of `sqlite3`, the database most commonly
used with drift.

{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.0.0
  path: ^{{ versions.path }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

If you're wondering why so many packages are necessary, here's a quick overview over what each package does:

- `drift`: This is the core package defining the APIs you use to access drift databases.
- `sqlite3_flutter_libs`: Ships the latest `sqlite3` version with your Android or iOS app. This is not required when you're _not_ using Flutter,
  but then you need to take care of including `sqlite3` yourself.
  For an overview on other platforms, see [platforms]({{ 'Platforms/index.md' | pageUrl }}).
  Note that the `sqlite3_flutter_libs` package will include the native sqlite3 library for the following
  architectures: `armv8`, `armv7`, `x86` and `x86_64`.
  Most Flutter apps don't run on 32-bit x86 devices without further setup, so you should
  [add a snippet](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3_flutter_libs#included-platforms)
  to your `build.gradle` if you don't need `x86` builds.
  Otherwise, the Play Store might allow users on `x86` devices to install your app even though it is not
  supported.
  In Flutter's current native build system, drift unfortunately can't do that for you.
- `path_provider` and `path`: Used to find a suitable location to store the database. Maintained by the Flutter and Dart team.
- `drift_dev`: This development-only dependency generates query code based on your tables. It will not be included in your final app.
- `build_runner`: Common tool for code-generation, maintained by the Dart team.

## Database class

Every project using drift needs at least one class to access a database. This class references all the
tables you want to use and is the central entrypoint for drift's code generator.
In this example, we'll assume that this database class is defined in a file called `database.dart` and
somewhere under `lib/`. Of course, you can put this class in any Dart file you like.

To make the database useful, we'll also add a simple table to it. This table, `TodoItems`, can be used
to store todo items for a todo list app.
Everything there is to know about defining tables in Dart is described on the [Dart tables]({{'Dart API/tables.md' | pageUrl}}) page.
If you prefer using SQL to define your tables, drift supports that too! You can read all about the [SQL API]({{ 'SQL API/index.md' | pageUrl }}) here.

For now, the contents of `database.dart` are:

{% include "blocks/snippet" snippets = snippets name = 'before_generation' %}

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
for migrations after changing the database, we can leave it at `1` for now. The database class
now looks like this:

{% include "blocks/snippet" snippets = snippets name = 'open' %}

## Next steps

Congratulations! With this setup complete, your project is ready to use drift.
This short snippet shows how the database can be opened and how to run inserts and selects:

{% include "blocks/snippet" snippets = snippets name = 'use' %}

But drift can do so much more! These pages provide more information useful when getting
started with drift:

- [Dart tables]({{ 'Dart API/tables.md' | pageUrl }}): This page describes how to write your own
  Dart tables and which classes drift generates for them.
- Writing queries: Drift-generated classes support writing the most common SQL statements, like
  [selects]({{ 'Dart API/select.md' | pageUrl }}) or [inserts, updates and deletes]({{ 'Dart API/writes.md' | pageUrl }}).
- Something to keep in mind for later: When changing the database, for instance by adding new columns
  or tables, you need to write a migration so that existing databases are transformed to the new
  format. Drift's extensive [migration tools]({{ 'Migrations/index.md' | pageUrl }}) help with that.

Once you're familiar with the basics, the [overview here]({{ 'index.md' | pageUrl }}) shows what
more drift has to offer.
This includes transactions, automated tooling to help with migrations, multi-platform support
and more.
