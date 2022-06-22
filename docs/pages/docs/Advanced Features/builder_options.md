---
data:
  title: "Builder options"
  description: >-
    Advanced options applied when writing the generated code
template: layouts/docs/single
aliases:
 - "options/"
---

The `drift_dev` package supports a range of options that control how code
is generated.
In most cases, the default settings should be sufficient. But if you want to
try out new features faster or configure how drift-generated code looks like,
you can use the available options listed below.
You can also see the section on [recommended options](#recommended-options) for
advice on which options to use.

To use the options, create a `build.yaml` file in the root of your project (e.g. next
to your `pubspec.yaml`):
```yaml
# build.yaml. This file is quite powerful, see https://pub.dev/packages/build_config

targets:
  $default:
    builders:
      drift_dev:
        options:
          compact_query_methods: true
```

## Available options

At the moment, drift supports these options:

* `write_from_json_string_constructor`: boolean. Adds a `.fromJsonString` factory
   constructor to generated data classes. By default, we only write a `.fromJson`
   constructor that takes a `Map<String, dynamic>`.
* `override_hash_and_equals_in_result_sets`: boolean. When drift generates another class
   to hold the result of generated select queries, this flag controls whether drift should
   override `operator ==` and `hashCode` in those classes. In recent versions, it will also
   override `toString` if this option is enabled.
* `compact_query_methods` (defaults to `true`):
   For queries declared on a `@DriftDatabase` or `@DriftAccessor` annotation, drift used to generate three methods:
   A base method returning a `Selectable` and then two helper methods returning a `Stream` or a `Future`.
   As the `Selectable` class contains its own methods to convert it to a `Stream` and `Future`, the two
   later methods only exist for backwards compatibility. When this flag is enabled, drift won't write them at all.
   This flag is enabled by default in moor 3.0 and drift, but it can still be disabled.
* `skip_verification_code`: Generated tables contain a significant chunk of code to verify integrity
  of inserted data and report detailed errors when the integrity is violated. If you're only using
  inserts with SQL, or don't need this functionality, enabling this flag can help to reduce the amount
  generated code.
* `use_data_class_name_for_companions`: By default, the name for [companion classes]({{ "../Getting started/writing_queries.md#updates-and-deletes" | pageUrl }})
  is based on the table name (e.g. a `@DataClassName('Users') class UsersTable extends Table` would generate
  a `UsersTableCompanion`). With this option, the name is based on the data class (so `UsersCompanion` in
  this case).
* `use_column_name_as_json_key_when_defined_in_moor_file` (defaults to `true`): When serializing columns declared inside a 
  `.moor` (or `.drift`) file from and to json, use their sql name instead of the generated Dart getter name
  (so a column named `user_name` would also use `user_name` as a json key instead of `userName`).
  You can always override the json key by using a `JSON KEY` column constraint
  (e.g. `user_name VARCHAR NOT NULL JSON KEY userName`).
* `generate_connect_constructor`: Generate necessary code to support the [isolate runtime]({{ "isolates.md" | pageUrl }}).
  This is a build option because isolates are still experimental. This will be the default option eventually.
* `eagerly_load_dart_ast`: Drift's builder will load the resolved AST whenever it encounters a Dart file,
  instead of lazily when it reads a table. This is used to investigate rare builder crashes.
* `data_class_to_companions` (defaults to `true`): Controls whether drift will write the `toCompanion` method in generated
   data classes.
* `mutable_classes` (defaults to `false`): The fields generated in generated data, companion and result set classes are final
  by default. You can make them mutable by setting `mutable_classes: true`.
* `raw_result_set_data`: The generator will expose the underlying `QueryRow` for generated result set classes
* `apply_converters_on_variables`: Applies type converters to variables in compiled statements.
* `generate_values_in_copy_with`: Generates a `Value<T?>` instead of `T?` for nullable columns in `copyWith`. This allows to set
  columns back to null (by using `Value(null)`). Passing `null` was ignored before, making it impossible to set columns
  to `null`.
* `named_parameters`: Generates named parameters for named variables in SQL queries.
* `named_parameters_always_required`: All named parameters (generated if `named_parameters` option is `true`) will be required in Dart.
* `new_sql_code_generation`: Generates SQL statements from the parsed AST instead of replacing substrings. This will also remove
  unnecessary whitespace and comments.
  If enabling this option breaks your queries, please file an issue!
* `scoped_dart_components`: Generates a function parameter for [Dart placeholders]({{ '../Using SQL/drift_files.md#dart-components-in-sql' | pageUrl }}) in SQL.
  The function has a parameter for each table that is available in the query, making it easier to get aliases right when using
  Dart placeholders.

## Assumed SQL environment

You can configure the SQL dialect you want to target with the `sql` build option.
When using sqlite, you can further configure the assumed sqlite3 version and enabled
extensions for more accurate analysis.

Note that these options are used for static analysis only and don't have an impact on the
actual sqlite version at runtime.

To define the sqlite version to use, set `sqlite.version` to the `major.minor`
version:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialect: sqlite
            options:
              version: "3.34"
```

With that option, the generator will emit warnings when using newer sqlite version.
For instance, using more than one [upsert clause](https://sqlite.org/lang_upsert.html) is not supported
in 3.34, so an error would be reported.
Currently, the generator can't provide compatibility checks for versions below 3.34, which is the
minimum version needed in options.

### Available extensions

__Note__: This enables extensions in the analyzer for custom queries only. For instance, when the `json1` extension is
enabled, the [`json`](https://www.sqlite.org/json1.html) functions can be used in drift files. This doesn't necessarily
mean that those functions are supported at runtime! Both extensions are available on iOS 11 or later. On Android, they're
only available when using a `NativeDatabase`.

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialect: sqlite
            options:
              modules:
                - json1
                - fts5
                - moor_ffi
```

We currently support the following extensions:

- [json1](https://www.sqlite.org/json1.html): Support static analysis for `json_` functions in moor files
- [fts5](https://www.sqlite.org/fts5.html): Support `CREATE VIRTUAL TABLE` statements for `fts5` tables and the `MATCH` operator.
  Functions like `highlight` or `bm25` are available as well.
- `moor_ffi`: Enables support for functions that are only available when using a `NativeDatabase`. This contains `pow`, `sqrt` and a variety
  of trigonometric functions. Details on those functions are available [here]({{ "../Other engines/vm.md#moor-only-functions" | pageUrl }}).
- `math`: Assumes that sqlite3 was compiled with [math functions](https://www.sqlite.org/lang_mathfunc.html).
  This module is largely incompatible with the `moor_ffi` module.

## Recommended options

In general, we recommend using the default options. However, some options will be enabled by default in a future drift release.
At the moment, they're opt-in to not break existing users. These options are:

- `apply_converters_on_variables`
- `generate_values_in_copy_with`
- `new_sql_code_generation`
- `scoped_dart_components`

We recommend enabling these options.

You can disable some default drift features and reduce the amount of generated code with the following options:

- `skip_verification_code: true`: You can remove a significant portion of generated code with this option. The 
  downside is that error messages when inserting invalid data will be less specific. 
- `data_class_to_companions: false`: Don't generate the `toCompanion` method on data classes. If you don't need that
  method, you can disable this option.

## Using drift classes in other builders

It is possible to use classes generated by drift in other builders.
Due to technicalities related to Dart's build system and `source_gen`, this approach requires a custom configuration
and minor code changes. Put this content in a file called `build.yaml` next to your `pubspec.yaml`:

```yaml
targets:
  $default:
    # disable the default generators, we'll only use the non-shared drift generator here
    auto_apply_builders: false
    builders:
      drift_dev|not_shared:
        enabled: true
        # If needed, you can configure the builder like this:
        # options:
        #   skip_verification_code: true
        #   use_experimental_inference: true
      # This builder is necessary for drift-file preprocessing. You can disable it if you're not
      # using .drift files with type converters.
      drift_dev|preparing_builder:
        enabled: true
  
  run_built_value:
    dependencies: ['your_package_name']
    builders:
      # Disable drift builders. By default, those would run on each target
      drift_dev:
        enabled: false
      drift_dev|preparing_builder:
        enabled: false
      # we don't need to disable drift|not_shared, because it's disabled by default
```

In all files that use generated drift code, you'll have to replace `part 'filename.g.dart'` with `part 'filename.drift.dart'`.
If you use drift _and_ another builder in the same file, you'll need both `.g.dart` and `.drift.dart` as part-files.

A full example is available as part of [the drift repo](https://github.com/simolus3/drift/tree/develop/examples/with_built_value).

If you run into any problems with this approach, feel free to open an issue on drift.

### The technicalities, explained

Almost all code generation packages use a so called "shared part file" approach provided by `source_gen`.
It's a common protocol that allows unrelated builders to write into the same `.g.dart` file.
For this to work, each builder first writes a `.part` file with its name. For instance, if you used `drift`
and `built_value` in the same project, those part files could be called `.drift.part` and `.built_value.part`.
Later, the common `source_gen` package would merge the part files into a single `.g.dart` file.

This works great for most use cases, but a downside is that each builder can't see the final `.g.dart`
file, or use any classes or methods defined in it. To fix that, drift offers an optional builder -
`drift_dev|not_shared` - that will generate a separate part file only containing
code generated by drift. So most of the work resolves around disabling the default generator of drift
and use the non-shared generator instead.

Finally, we need to the build system to run drift first, and all the other builders otherwise. This is
why we split the builders up into multiple targets. The first target will only run drift, the second
target has a dependency on the first one and will run all the other builders.
