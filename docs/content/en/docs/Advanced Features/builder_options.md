---
title: "Builder options"
description: >-
  Advanced options applied when writing the generated code
---

The `moor_generator` package has some options that control how the 
code is generated. Note that, in most cases, the default settings
should be sufficient. See the section on recommended settings below.

To use the options, create a `build.yaml` file in the root of your project (e.g. next
to your `pubspec.yaml`):
```yaml
# build.yaml. This file is quite powerful, see https://pub.dev/packages/build_config

targets:
  $default:
    builders:
      moor_generator:
        options:
          compact_query_methods: true
```

## Available options

At the moment, moor supports these options:

* `write_from_json_string_constructor`: boolean. Adds a `.fromJsonString` factory
   constructor to generated data classes. By default, we only write a `.fromJson`
   constructor that takes a `Map<String, dynamic>`.
* `override_hash_and_equals_in_result_sets`: boolean. When moor generates another class
   to hold the result of generated select queries, this flag controls whether moor should
   override `operator ==` and `hashCode` in those classes.
* `compact_query_methods`: For queries declared on a `@UseMoor` or `@UseDao` annotation, moor
   will generate three methods: A base method returning a `Selectable` and then two helper 
   methods returning a `Stream` or a `Future`. As the `Selectable` class contains its own methods
   to convert it to a `Stream` and `Future`, the two later methods only exist for backwards
   compatibility. When this flag is enabled, moor won't write them at all. This will be the only
   option in moor 3.0
* `skip_verification_code`: Generated tables contain a significant chunk of code to verify integrity
  of inserted data and report detailed errors when the integrity is violated. If you're only using
  inserts with SQL, or don't need this functionality, enabling this flag can help to reduce the amount
  generated code.
* `use_data_class_name_for_companions`: By default, the name for [companion classes]({{< relref "../Getting started/writing_queries.md#updates-and-deletes" >}})
  is based on the table name (e.g. a `@DataClassName('Users') class UsersTable extends Table` would generate
  a `UsersTableCompanion`). With this option, the name is based on the data class (so `UsersCompanion` in
  this case).
* `use_column_name_as_json_key_when_defined_in_moor_file`: When serializing columns declared inside a 
  `.moor` file from and to json, use their sql name instead of the generated Dart getter name
  (so a column named `user_name` would also use `user_name` as a json key instead of `userName`).
  This will be the only option in moor 3.0. You can always override the json key by using a `JSON KEY`
  column constraint (e.g. `user_name VARCHAR NOT NULL JSON KEY userName`)
* `generate_connect_constructor`: Generate necessary code to support the [isolate runtime]({{< relref "isolates.md" >}}).
  This is a build option because isolates are still experimental. This will be the default option eventually.
* `use_experimental_inference`: Use a new, experimental type inference algorithm when analyzing sql statements. The 
  algorithm is designed to yield more accurate results on nullability and complex constructs. Note that it's in a 
  preview state at the moment, which means that generated code might change after a minor update.
* `sqlite_modules`: This list can be used to enable sqlite extensions, like those for json or full-text search.
  Modules have to be enabled explicitly because they're not supported on all platforms. See the following section for
  details.
* `use_experimental_inference`: Enables a new type inference algorithm for sql statements.
  The new algorithm is much better at handling complex statements and nullability. 
  However, it's still in development and may not work in all cases yet. Please report any issues you can find.
  __Warning:__ The new type inference algorithm is in development and does not obey to semantic versioning.
  Results and generated code might change in moor versions not declared as breaking.

## Available extensions

__Note__: This enables extensions in the analyzer for custom queries only. For instance, when the `json1` extension is
enabled, the [`json`](https://www.sqlite.org/json1.html) functions can be used in moor files. This doesn't necessarily
mean that those functions are supported at runtime! Both extensions are available on iOS 11 or later. On Android, they're
only available when using `moor_ffi`. See [our docs]({{< relref "extensions.md" >}}) for more details on them.

```yaml
targets:
  $default:
    builders:
      moor_generator:
        options:
          sqlite_modules:
            - json1
            - fts5
```

We currently support the [json1](https://www.sqlite.org/json1.html) and [fts5](https://www.sqlite.org/fts5.html) extensions
for static analysis. Feel free to create an issue if you need support for different extensions.

## Recommended options

In general, we recommend not enabling these options unless you need to. There are some exceptions though:

- `compact_query_methods` and `use_column_name_as_json_key_when_defined_in_moor_file`: We recommend enabling 
  both flags for new projects because they'll be the only option in the next breaking release.
- `skip_verification_code`: You can remove a significant portion of generated code with this option. The 
  downside is that error messages when inserting invalid data will be less specific. 
