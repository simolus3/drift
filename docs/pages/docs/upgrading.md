---
data:
  title: "Upgrading"
  description: >-
    How to upgrade between major drift versions
template: layouts/docs/single
aliases: ["/name"]
---

## Migrating from drift 1.x to drift 2.x

The first major upgrade from drift 1 to drift 2 involves a number of breaking
changes and the removal of legacy features. These changes make drift easier to
maintain and easier to use.

This overview describes important breaking changes and how to apply them to your
project. For a full list of updates, see the [changelog](https://pub.dev/packages/drift/changelog).

1. __Null-safety only__: Drift will always emit null-safe code now. To use drift
   2.x, please migrate your application (or at least the parts defining the
   database) to Dart 2.12 or later.
2. Instances of `Expression` __always have a non-nullable type parameter__ now.
   That is, use `Expression<int>` instead of `Expression<int?>`.
   The old distinction was an attempt to embed SQL's behavior around `NULL`
   values into Dart's typesystem. This didn't work, and so expressions no longer
   have associated nullability in their types.
3. __Reading nullable expressions__: `QueryRow.read` (used to read columns from
   a complex select in Dart) only supports non-nullable values now. To read
   nullable values, use `readNullable`.
4. __Updated type converters__: The `mapToSql` and `mapToDart` methods have been
   renamed to simply `toSql` and `fromSql`, respectively.
   Also, a type converter only needs to support the exact types that it was
   declared with. In particular, a `TypeConverter<MyObject, String>` no longer
   needs to deal with `null` values in either direction.

   Type converters that are declared as nullable (e.g. `TypeConverter<Foo?, int?>`)
   can no longer be applied to non-nullable columns. These changes bring proper
   null-safety support to type converters and make their behavior around null
   values more intuitive.
5. __Changed builder options__: To reduce the complexity of `drift_dev`, and to
   make some long-recommended builder options the default, some options have been
   removed or had their defaults changed.
  - The following options are no longer available:
    - `new_sql_code_generation`: Always enabled now. If this changes the behavior
      of your queries, please open an issue!
    - `null_aware_type_converters`: This is always enabled now with the new
      semantics for type converters.
    - `compact_query_methods`: Has been enabled by default before, can no longer
      be disabled now.
    - `eagerly_load_dart_ast`: This option used to not do anything for a while
      and has been removed entirely now.
  - In addition, the defaults for these options has changed (but the existing
    behavior can be restored if desired):
     - `apply_converters_on_variables` is enabled by default now.
     - `generate_values_in_copy_with` is enabled by default now.
     - `scoped_dart_components` is enabled by default now.
6. The generated `fromData` factory on data classes is no longer generated. Use
   the `map` methods on the table instance instead (e.g. `database.users.map`
   instead of `User.fromData`).

The breaking changes in drift 2.0 are motivated by making drift easier to
maintain and to unblock upcoming new features. This release also provides some
new features, like nested transactions or support for `RETURNING` for updates
and deletes in the Dart API.
We hope the upgrade is worthwhile. If you run into any issues, please do not
hesistate to [start a new discussion](https://github.com/simolus3/drift/discussions)
or to [open an issue](https://github.com/simolus3/drift/issues).
Thanks for using drift!

## Migrating from `moor` to `drift` {#name}

Moor has been renamed to `drift`. The reason for this is that, in some parts of the world, moor may be used as a derogatory term.
I have not been aware of this when starting this project, but we believe that the current name does not reflect the inclusivity of the Dart and Flutter communities.
Despite the associated effort, I'm convinced that renaming the project is the right decision.
Thank you for your understanding!

Until version `5.0.0`, the current `moor`, `moor_flutter` and `moor_generator` packages will continue to work - __no urgent action is necessary__.
All features and fixes to the new `drift` packages will be mirrored in `moor` as well.
With the release of drift 2.0.0, the `moor` set of packages have been discontinued in favor of `drift` and `drift_dev`.

This page describes how to migrate from the old `moor` package to the new `drift` package.
This process can be automated, and we hope that the migration is a matter of minutes for you.
In case of issues with the tool, this page also describes how to manually migrate to the new `drift` packages.

### Automatic migration

To make the name change as easy as possible for you, drift comes with an automatic migration tool for your
project.
It will analyze your source files and perform all changes that come with this migration.

To use the migration tool, please first make sure that you're using `moor_generator` version `4.6.0` or later,
for instance by updating your dependency on it:

```yaml
dev_dependencies:
  moor_generator: ^4.6.0
```

Next, please make sure that your project does not contain analysis errors, as this could make the migration tool
less effective.
Also, please __create a backup of your project's files__ before running the migration tool. It will override parts of
your sources without further confirmation. When using git, it is sufficient to ensure that you have a clean state.

To apply the migration, run `dart run moor_generator migrate` in your project's directory.
The migration tool will transform your pubspec, `build.yaml` files and Dart source files. It will also rename `.moor` files to
`.drift` and patch imports as needed.

After running the migration, please verify the changes to ensure that they match what you expect.
Also, you may have to

- Format your sources again: Run `dart format .`.
- Re-run the build: Run `dart run build_runner build -d`.
  - If you have been using generated [migration test files]({{ 'Migrations/exports.md' | pageUrl }}),
    re-generate them as well with `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`
    (you may have to adapt the command to the directories you use for schemas).
- Manually fix the changed order of imports caused by the migration.

Congratulations, your project is now using drift!

If you run into any issues with the automatic migration tool, please [open an issue](https://github.com/simolus3/drift/issues/new/).

### Manual migration

To migrate from `moor` to `drift`, you may have to update:

- Your pubspec
- Dart imports
- Dart code, to reflect new API names
- Your `build.yaml` configuration files, if any

The following sections will describe each of the steps.

#### New dependencies

{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}

First, replace the `moor` dependency with `drift` and `moor_generator` with `drift_dev`, respectively:

```yaml
dependencies:
  drift: ^{{ versions.drift }}
dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
```

If you've been using `moor_flutter`, also add a dependency on `drift_sqflite: ^1.0.0`.

Run `pub get` to get the new packages.

#### Changing Dart imports

This table compares the old imports from `moor` and the new imports for `drift`:

| Moor import                              | Drift import                               |
| ---------------------------------------- | ------------------------------------------ |
| `package:moor/extensions/json1.dart`     | `package:drift/extensions/json1.dart`      |
| `package:moor/extensions/moor_ffi.dart`  | `package:drift/extensions/native.dart`     |
| `package:moor/backends.dart`             | `package:drift/backends.dart`              |
| `package:moor/ffi.dart`                  | `package:drift/native.dart`                |
| `package:moor/isolate.dart`              | `package:drift/isolate.dart`               |
| `package:moor/moor_web.dart`             | `package:drift/web.dart`                   |
| `package:moor/moor.dart`                 | `package:drift/drift.dart`                 |
| `package:moor/remote.dart`               | `package:drift/remote.dart`                |
| `package:moor/sqlite_keywords.dart`      | `package:drift/sqlite_keywords.dart`       |
| `package:moor_flutter/moor_flutter.dart` | `package:drift_sqflite/drift_sqflite.dart` |

#### Changing Dart code

This table compares old moor-specific API names and new names as provided by `drift`:

| Moor name              | Drift name                         |
| ---------------------- | ---------------------------------- |
| `VmDatabase`           | `NativeDatabase`                   |
| `MoorIsolate`          | `DriftIsolate`                     |
| `MoorWebStorage`       | `DriftWebStorage`                  |
| `@UseMoor`             | `@DriftDatabase`                   |
| `@UseDao`              | `@DriftAccessor`                   |
| `MoorWrappedException` | `DriftWrappedException`            |
| `MoorRuntimeOptions`   | `DriftRuntimeOptions`              |
| `moorRuntimeOptions`   | `driftRuntimeOptions`              |
| `$mrjc` and `$mrjf`    | Use `Object.hash` from `dart:core` |
| `MoorServer`           | `DriftServer`                      |
| `FlutterQueryExecutor` | `SqfliteQueryExecutor`             |

#### (Optional: Rename moor files)

For consistency, you can rename your `.moor` files to `.drift`.
The drift generator will continue to accept `.moor` files though.

If you opt for a rename, also update your imports and `include:` parameters in database and DAO classes.

#### Build configuration

When configuring moor builders for [options]({{ 'Generation options/index.md' | pageUrl }}), you have to update your `build.yaml` files to reflect the new builder keys:

| Moor builder key                            | Drift builder key              |
| ------------------------------------------- | ------------------------------ |
| `moor_generator\|preparing_builder`         | `drift_dev\|preparing_builder` |
| `moor_generator\|moor_generator`            | `drift_dev\|drift_dev`         |
| `moor_generator`                            | `drift_dev`                    |
| `moor_generator\|moor_generator_not_shared` | `drift_dev\|not_shared`        |
| `moor_generator\|moor_cleanup`              | `drift_dev\|cleanup`           |
