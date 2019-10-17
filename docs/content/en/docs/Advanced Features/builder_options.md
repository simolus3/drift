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
          write_from_json_string_constructor: true
```

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

## Recommended options

In general, we recommend not enabling these options unless you need to. There are some exceptions though:

- `compact_query_methods` and `use_column_name_as_json_key_when_defined_in_moor_file`: We recommend enabling 
  both flags for new projects because they'll be the only option in the next breaking release.
- `skip_verification_code`: You can remove a significant portion of generated code with this option. The 
  downside is that error messages when inserting invalid data will be less specific. 