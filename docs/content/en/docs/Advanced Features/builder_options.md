---
title: "Builder options"
description: >-
  Advanced options applied when writing the generated code
---

The `moor_generator` package has some options that control how the 
code is generated. Note that, in most cases, the default settings
should be sufficient.

To use the options, create a `build.yaml` file in the root of your project (e.g. next
to your `pubspec.yaml`):
```yaml
# build.yaml. This file is quite powerful, see https://pub.dev/packages/build_config

targets:
  $default:
    builders:
      moor_generator:
        options:
          generate_private_watch_methods: true
```

At the moment, moor supports these options:

* `generate_private_watch_methods`: boolean. There was a bug in the generator where
  [compiled queries]({{<relref "../Using SQL/custom_queries.md">}}) that start with
  an underscore did generate a watch method that didn't start with an underscore
  (see [#107](https://github.com/simolus3/moor/issues/107)). Fixing this would be
  a breaking change, so the fix is opt-in by enabling this option. This flag is
  available since 1.7 and will be removed in moor 2.0, where this flag will always
  be enabled.
* `write_from_json_string_constructor`: boolean. Adds a `.fromJsonString` factory
   constructor to generated data classes. By default, we only write a `.fromJson`
   constructor that takes a `Map<String, dynamic>`.