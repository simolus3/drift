---

title: Exporting schemas
description: Store all schema versions of your app for validation.

---


!!! warning "Important Note"

    This command is specifically for exporting schemas.
    If you are using the `make-migrations` command, this is already done for you.

By design, drift's code generator can only see the current state of your database
schema. When you change it, it can be helpful to store a snapshot of the older
schema in a file.
Later, drift tools can take a look at all the schema files to validate the migrations
you write.

We recommend exporting the initial schema once. Afterwards, each changed schema version
(that is, every time you change the `schemaVersion` in the database) should also be
stored.
This guide assumes a top-level `drift_schemas/` folder in your project to store these
schema files, like this:

```
my_app
  .../
  lib/
    database/
      database.dart
      database.g.dart
  test/
    generated_migrations/
      schema.dart
      schema_v1.dart
      schema_v2.dart
  drift_schemas/
    drift_schema_v1.json
    drift_schema_v2.json
  pubspec.yaml
```

Of course, you can also use another folder or a subfolder somewhere if that suits your workflow
better.

Exporting schemas and generating code for them can't be done with `build_runner` alone, which is
why this setup described here is necessary.

We hope it's worth it though! Verifying migrations can give you confidence that you won't run
into issues after changing your database.
If you get stuck along the way, don't hesitate to [open a discussion about it](https://github.com/simolus3/drift/discussions).

## Exporting the schema

To begin, let's create the first schema representation:

```
$ mkdir drift_schemas
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/
```

This instructs the generator to look at the database defined in `lib/database/database.dart` and extract
its schema into the new folder.

After making a change to your database schema, you can run the command again. For instance, let's say we
made a change to our tables and increased the `schemaVersion` to `2`. To dump the new schema, just run the
command again:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/
```

You'll need to run this command every time you change the schema of your database and increment the `schemaVersion`.

Drift will name the files in the folder `drift_schema_vX.json`, where `X` is the current `schemaVersion` of your
database.
If drift is unable to extract the version from your `schemaVersion` getter, provide the full path explicitly:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v3.json
```

!!! success "<i class="fas fa-lightbulb"></i> Dumping a database"


    If, instead of exporting the schema of a database class, you want to export the schema of an existing sqlite3
    database file, you can do that as well! `drift_dev schema dump` recognizes a sqlite3 database file as its first
    argument and can extract the relevant schema from there.

## What next?

Having exported your schema versions into files like this, drift tools are able
to generate code aware of multiple schema versions.

This enables [step-by-step migrations](step_by_step.md): Drift
can generate boilerplate code for every schema migration you need to write, so that
you only need to fill in what has actually changed. This makes writing migrations
much easier.

By knowing all schema versions, drift can also [generate test code](tests.md#writing-tests),
which makes it easy to write unit tests for all your schema migrations.

## Debugging issues exporting your schema

!!! warning

    This describes a specific issue exporting schemas in detail that is not relevant to most users.
    Drift will point you toward this section when it runs into the problems described here.

First and foremost, drift is a code generator: It generates Dart classes based on your definitions that
are responsible for constructing the `CREATE TABLE` statements at runtime.
While drift has a pretty good idea about your database schema just by looking at your code (something
it needs to be capable of to generate typesafe code), some details require running Dart.

A common example for this are [defaults](../dart_api/tables.md#default-values):
They are typically defined like this, which might be easy to analyze:

```dart
class Entries extends Table {
  TextColumn get content => text().withDefault(const Constant('test'))();
}
```

However, nothing stops you from doing this:

```dart
String computeDefaultContent() {
  // ...
}

class Entries extends Table {
  TextColumn get content => text().withDefault(Constant(computeDefaultContent()))();
}
```

Since drift schemas aim to be a complete representation of your database (which includes default
values), we have to run parts of the code like `computeDefaultContent`!

In older drift versions, this issue was solved by just embedding the source code (like `computeDefaultContent()`) in the schema file.
When you generate migration code, that code would also call `computeDefaultContent` which would
restore the schema at runtime (allowing drift to compare it to actual schemas for tests).
This approach has two __fatal flaws__:

1. When you later remove the `computeDefaultContent` method because later schema versions don't
   require it anymore, generated code for older schema versions calls a method that doesn't exist.
2. When you later change the implementation of `computeDefaultContent`, that implicitly changes the
   schema (and requires a migration).
   But since drift schemas only know that `computeDefaultContent()` needs to be evaluated, they
   don't know what `computeDefaultContent()` _used to_ evaluate to at older schemas.

To fix this, drift attempts to run parts of your database code. So if `computeDefaultContent()`
evaluates to `hello world` at the time `make-migrations` or `schema export` is invoked on the
command-line, drift will internally rewrite the table like this:

```dart
class Entries extends Table {
  TextColumn get content => text().withDefault(const Constant('hello world'))();
}
```

When you later change or remove `computeDefaultContent()`, this has no impact on the correctness
of schema tests.

So while running parts of your database code from the CLI is a requirement for good schema exports,
it's unfortunately not without problems.
You run `drift_dev` with `dart`, but your app may well import Flutter-specific APIs:

```dart
import 'package:flutter/material.dart' show Colors;

class Users extends Table {
  IntColumn get profileBackgroundColor =>
      integer().withDefault(Constant(Colors.red.shade600.value))();
}
```

To evaluate the default value here, we'd have to evaluate `Colors.red.shade600.value`. And since
`Color` is defined in `dart:ui` (which is not available to Dart CLI apps), drift won't be able to analyze
the schema.
Due to the way imports work in Dart, this can also be a problem when defining constants in Dart
files that import Flutter:

```dart
// constants.dart
import 'package:flutter/flutter.dart';

const defaultUserName = 'name';
```

```dart
import 'constants.dart';

class Users extends Table {
  // This is a problem: make-migrations has to import constants.dart, which depends on Flutter
  TextColumn get name => text().withDefault(const Constant(defaultUserName))();
}
```

On the other hand, importing Flutter into the database file alone is not a problem:

```dart
import 'package:drift_flutter/drift_flutter.dart';

class Users extends Table {
  // Not a problem; withDefault only references core drift APIs (`Constant`)
  TextColumn get name => text().withDefault(const Constant('name'))();
}
```

Drift will remove things that don't affect the schema (like `clientDefault`, or type converters).
Those are all free to import Flutter-specific APIs.

### Fixing this

When drift fails to analyze your schema and prints an exception pointing to this section of the
documentation, it's typically possible to restructure your code to avoid the problem.

First, it's necessary to understand the problem. You can instruct drift to dump the internal code
it uses to run your database:

```
dart run drift_dev make-migrations --export-schema-startup-code=schema_description.dart
```

Next, try running this code yourself to reproduce the error:

```
dart run schema_description.dart
```

The Dart compiler will print an explanation on the paths that lead to unsupported libraries
like Flutter.

With that, it's possible to eliminate them:

1. Check why drift is importing a Flutter-specific file. Does it define a method or field used in
   a default value?
2. Try restructuring your code so that these definitions are moved into a file that doesn't import
   Flutter.
3. Repeat!

While we hope that this will not affect most users, it can be a challenging issue to resolve.
If you need more guidance, please comment on [this issue](https://github.com/simolus3/drift/issues/3403).