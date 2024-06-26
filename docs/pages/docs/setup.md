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

First, let's add drift to your project's `pubspec.yaml`.
In addition to the core drift dependencies (`drift` and `drift_dev` to generate code), we're also
adding a package to open database on the respective platform.

{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}

{% block "blocks/tabbar" title = "Framework:" entries = 'Flutter (sqlite3),Dart (sqlite3),Dart (Postgres)' | split: ',' %}
{% block "blocks/tab" default = true %}
```yaml
dependencies:
  drift: ^{{ versions.drift }}
  drift_flutter: ^0.1.0

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

{% endblock %}
{% block "blocks/tab" %}
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
{% endblock %}
{% block "blocks/tab" %}
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
to [configure]({{ 'Generation options/index.md' | pageUrl }}) `drift_dev`:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialect:
              - postgres
              # Uncomment if you need to support both
#              - sqlite
```
{% endblock %}
{% endblock %}

## Database class

Every project using drift needs at least one class to access a database. This class references all the
tables you want to use and is the central entry point for drift's code generator.
In this example, we'll assume that this database class is defined in a file called `database.dart` and
somewhere under `lib/`. Of course, you can put this class in any Dart file you like.

To make the database useful, we'll also add a simple table to it. This table, `TodoItems`, can be used
to store todo items for a todo list app.
Everything there is to know about defining tables in Dart is described on the [Dart tables]({{'Dart API/tables.md' | pageUrl}}) page.
If you prefer using SQL to define your tables, drift supports that too! You can read all about the [SQL API]({{ 'SQL API/index.md' | pageUrl }}) here.

For now, populate the contents of `database.dart` with these tables which could form the persistence
layer of a simple todolist application:

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
for migrations after changing the database, we can leave it at `1` for now. Update `database.dart`
so it now looks like this:

<a name="open"></a>

{% block "blocks/tabbar" title = "Framework:" entries = 'Flutter (sqlite3),Dart (sqlite3),Dart (Postgres)' | split: ',' %}
{% block "blocks/tab" default = true %}
{% include "blocks/snippet" snippets = snippets name = 'flutter' %}

If you need to customize how databases are opened, you can also set the connection
up manually:
{% block "blocks/collapsible" title="Manual database setup" %}
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
{% endblock %}
{% endblock %}
{% block "blocks/tab" %}
{% include "blocks/snippet" snippets = snippets name = 'sqlite3' %}
{% endblock %}
{% block "blocks/tab" %}
{% include "blocks/snippet" snippets = snippets name = 'postgres' %}
{% endblock %}
{% endblock %}

## Next steps

Congratulations! With this setup complete, your project is ready to use drift.
This short snippet shows how the database can be opened and how to run inserts and selects:

{% include "blocks/snippet" snippets = snippets name = 'use' %}

But drift can do so much more! These pages provide more information useful when getting
started with drift:

- [Dart tables]({{ 'Dart API/tables.md' | pageUrl }}): This page describes how to write your own
  Dart tables and which classes drift generates for them.
- For new drift users or users not familiar with SQL, the [manager]({{ 'Dart API/manager.md' | pageUrl }}) APIs
  for tables allows writing most queries with a syntax you're likely familiar with from ORMs or other
  packages.
- Writing queries: Drift-generated classes support writing the most common SQL statements, like
  [selects]({{ 'Dart API/select.md' | pageUrl }}) or [inserts, updates and deletes]({{ 'Dart API/writes.md' | pageUrl }}).
- Something to keep in mind for later: When changing the database, for instance by adding new columns
  or tables, you need to write a migration so that existing databases are transformed to the new
  format. Drift's extensive [migration tools]({{ 'Migrations/index.md' | pageUrl }}) help with that.

Once you're familiar with the basics, the [overview here]({{ 'index.md' | pageUrl }}) shows what
more drift has to offer.
This includes transactions, automated tooling to help with migrations, multi-platform support
and more.
