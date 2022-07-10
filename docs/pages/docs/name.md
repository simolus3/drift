---
data:
  title: "Moor and Drift"
  description: >-
    Information about the name change from `moor` to `drift`
template: layouts/docs/single
path: /name
---

Moor has been renamed to `drift`. The reason for this is that, in some parts of the world, moor may be used as a derogatory term.
I have not been aware of this when starting this project, but we believe that the current name does not reflect the inclusivity of the Dart and Flutter communities.
Despite the associated effort, I'm convinced that renaming the project is the right decision.
Thank you for your understanding!

Until version `5.0.0`, the current `moor`, `moor_flutter` and `moor_generator` packages will continue to work - __no urgent action is necessary__.
All features and fixes to the new `drift` packages will be mirrored in `moor` as well.
At the next breaking release, the `moor` set of packages will be discontinued in favor of `drift` and `drift_dev`.

This page describes how to migrate from the old `moor` package to the new `drift` package.
This process can be automated, and we hope that the migration is a matter of minutes for you.
In case of issues with the tool, this page also describes how to manually migrate to the new `drift` packages.

## Automatic migration

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
When using Flutter, run `flutter pub run moor_generator migrate` instead.
The migration tool will transform your pubspec, `build.yaml` files and Dart source files. It will also rename `.moor` files to
`.drift` and patch imports as needed.

After running the migration, please verify the changes to ensure that they match what you expect.
Also, you may have to

- Format your sources again: Run `dart format .` or `flutter format .`
- Re-run the build: Run `dart run build_runner build` or `flutter pub run build_runner build --delete-conflicting-outputs`, respectively.
- Manually fix the changed order of imports caused by the migration.

Congratulations, your project is now using drift!

If you run into any issues with the automatic migration tool, please [open an issue](https://github.com/simolus3/drift/issues/new/).

## Manual migration

To migrate from `moor` to `drift`, you may have to update:

- Your pubspec
- Dart imports
- Dart code, to reflect new API names
- Your `build.yaml` configuration files, if any

The following sections will describe each of the steps.

### New dependencies

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

### Changing Dart imports

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

### Changing Dart code

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

### (Optional: Rename moor files)

For consistency, you can rename your `.moor` files to `.drift`.
The drift generator will continue to accept `.moor` files though.

If you opt for a rename, also update your imports and `include:` parameters in database and DAO classes.

### Build configuration

When configuring moor builders for [options]({{ 'Advanced Features/builder_options.md' | pageUrl }}), you have to update your `build.yaml` files to reflect the new builder keys:

| Moor builder key                            | Drift builder key              |
| ------------------------------------------- | ------------------------------ |
| `moor_generator\|preparing_builder`         | `drift_dev\|preparing_builder` |
| `moor_generator\|moor_generator`            | `drift_dev\|drift_dev`         |
| `moor_generator`                            | `drift_dev`                    |
| `moor_generator\|moor_generator_not_shared` | `drift_dev\|not_shared`        |
| `moor_generator\|moor_cleanup`              | `drift_dev\|cleanup`           |
