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
          store_date_time_values_as_text: true
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
* `skip_verification_code`: Generated tables contain a significant chunk of code to verify integrity
  of inserted data and report detailed errors when the integrity is violated. If you're only using
  inserts with SQL, or don't need this functionality, enabling this flag can help to reduce the amount
  generated code.
* `use_data_class_name_for_companions`: By default, the name for [companion classes]({{ "../Getting started/writing_queries.md#updates-and-deletes" | pageUrl }})
  is based on the table name (e.g. a `@DataClassName('Users') class UsersTable extends Table` would generate
  a `UsersTableCompanion`). With this option, the name is based on the data class (so `UsersCompanion` in
  this case).
* `use_column_name_as_json_key_when_defined_in_moor_file` (defaults to `true`): When serializing columns declared inside a
  `.drift` file from and to json, use their sql name instead of the generated Dart getter name
  (so a column named `user_name` would also use `user_name` as a json key instead of `userName`).
  You can always override the json key by using a `JSON KEY` column constraint
  (e.g. `user_name VARCHAR NOT NULL JSON KEY userName`).
* `generate_connect_constructor` (deprecated): Generates a named `connect()` constructor on database classes
  that takes a `DatabaseConnection` instead of a `QueryExecutor`.
  This option was deprecated in drift 2.5 because `DatabaseConnection` now implements `QueryExecutor`.
* `data_class_to_companions` (defaults to `true`): Controls whether drift will write the `toCompanion` method in generated
   data classes.
* `mutable_classes` (defaults to `false`): The fields generated in generated data, companion and result set classes are final
  by default. You can make them mutable by setting `mutable_classes: true`.
* `raw_result_set_data`: The generator will expose the underlying `QueryRow` for generated result set classes
* `apply_converters_on_variables` (defaults to `true`): Applies type converters to variables in compiled statements.
* `generate_values_in_copy_with` (defaults to `true`): Generates a `Value<T?>` instead of `T?` for nullable columns in `copyWith`. This allows to set
  columns back to null (by using `Value(null)`). Passing `null` was ignored before, making it impossible to set columns
  to `null`.
* `named_parameters`: Generates named parameters for named variables in SQL queries.
* `named_parameters_always_required`: All named parameters (generated if `named_parameters` option is `true`) will be required in Dart.
* `scoped_dart_components` (defaults to `true`): Generates a function parameter for [Dart placeholders]({{ '../Using SQL/drift_files.md#dart-components-in-sql' | pageUrl }}) in SQL.
  The function has a parameter for each table that is available in the query, making it easier to get aliases right when using
  Dart placeholders.
* `store_date_time_values_as_text`: Whether date-time columns should be stored as ISO 8601 string instead of a unix timestamp.
  For more information on these modes, see [datetime options]({{ '../Getting started/advanced_dart_tables#datetime-options' | pageUrl }}).
* `case_from_dart_to_sql` (defaults to `snake_case`): Controls how the table and column names are re-cased from the Dart identifiers.
  The possible values are  `preserve`, `camelCase`, `CONSTANT_CASE`, `snake_case`, `PascalCase`, `lowercase` and `UPPERCASE` (default: `snake_case`).
* `write_to_columns_mixins`: Whether the `toColumns` method should be written as a mixin instead of being added directly to the data class.
   This is useful when using [existing row classes]({{ 'custom_row_classes.md' | pageUrl }}), as the mixin is generated for those as well.
* `fatal_warnings`: When enabled (defaults to `false`), warnings found by `drift_dev` in the build process (like syntax errors in SQL queries or
  unresolved references in your Dart tables) will cause the build to fail.
* `preamble`: This option is useful when using drift [as a standalone part builder](#using-drift-classes-in-other-builders) or when running a
  [modular build](#modular-code-generation). In these setups, the `preamble` option defined by the [source_gen package](https://pub.dev/packages/source_gen#preamble)
  would have no effect, which is why it has been added as an option for the drift builders.

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

With that option, the generator will emit warnings when using features introduced
in more recent sqlite versions.
For instance, using more than one [upsert clause](https://sqlite.org/lang_upsert.html) is not supported
in 3.34, so an error would be reported.
Currently, the generator can't provide compatibility checks for versions below 3.34, which is the
minimum version needed in options.

### Multi-dialect code generation

Thanks to community contributions, drift has in-progress support for Postgres and MariaDB.
You can change the `dialect` option to `postgres` or `mariadb` to generate code for those
database management systems.

In some cases, your generated code might have to support more than one DBMS. For instance,
you might want to share database code between your backend and a Flutter app. Or maybe
you're writing a server that should be able to talk to both MariaDB and Postgres, depending
on what the operator prefers.
Drift can generate code for multiple dialects - in that case, the right SQL will be chosen
at runtime when it makes a difference.

To enable this feature, remove the `dialect` option in the `sql` block and replace it with
a list of `dialects`:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialects:
              - sqlite
              - postgres
            options:
              version: "3.34"
```

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
                - math
```

We currently support the following extensions:

- [json1](https://www.sqlite.org/json1.html): Support static analysis for `json_` functions in moor files
- [fts5](https://www.sqlite.org/fts5.html): Support `CREATE VIRTUAL TABLE` statements for `fts5` tables and the `MATCH` operator.
  Functions like `highlight` or `bm25` are available as well.
- `rtree`: Static analysis support for the [R*Tree](https://www.sqlite.org/rtree.html) extension.
  Enabling this option is safe when using a `NativeDatabase` with `sqlite3_flutter_libs`,
  which compiles sqlite3 with the R*Tree extension enabled.
- `moor_ffi`: Enables support for functions that are only available when using a `NativeDatabase`. This contains `pow`, `sqrt` and a variety
  of trigonometric functions. Details on those functions are available [here]({{ "../Other engines/vm.md#moor-only-functions" | pageUrl }}).
- `math`: Assumes that sqlite3 was compiled with [math functions](https://www.sqlite.org/lang_mathfunc.html).
  This module is largely incompatible with the `moor_ffi` module.
- `spellfix1`: Assumes that the [spellfix1](https://www.sqlite.org/spellfix1.html)
  module is available. Note that this is not the case for most sqlite3 builds,
  including the ones shipping with `sqlite3_flutter_libs`.

### Known custom functions

The `modules` options can be used to tell drift's analyzer that a well-known
sqlite3 extension is available at runtime. In some backends (like a `NativeDatabase`),
it is also possible to specify entirely custom functions.

To be able to use these functions in `.drift` files, you can tell drift's
analyzer about them. To do so, add a `known_functions` block to the options:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sql:
            dialect: sqlite
            options:
              known_functions:
                my_function: "boolean (text, int null)"
```

With these options, drift will analyze queries under the assumption that a SQL
function called `my_function` taking a non-nullable textual value an a nullable
integer will return a non-null value that drift can interpret as a boolean.

The syntax for a function type is defined as `<return type> (<argument types>)`.
Each type consists of an arbitrary word used to determine [column affinity](https://www.sqlite.org/datatype3.html#determination_of_column_affinity),
with drift also supporting `DATETIME` and `BOOLEAN` as type hints. Then, the
optional `NULL` keyword can be used to indicate whether the type is nullable.

## Recommended options

In general, we recommend using the default options.
{%- comment %}
However, some options will be enabled by default in a future drift release.
At the moment, they're opt-in to not break existing users. These options are:

(Currently all recommended options are also the default)

We recommend enabling these options.

{% endcomment %}
However, you can disable some default drift features and reduce the amount of generated code with the following options:

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

## Modular code generation

By default, drift generates code from a single entrypoint - all tables, views
and queries for a database are generated into a single part file.
For larger projects, this file can become quite large, slowing down builds and
the analyzer when it is re-generated.
Drift supports an alternative and modular code-generation mode intended as an
alternative for larger projects.
With this setup, drift generates multiple files and automatically manages
imports between them.

As a motivating example, consider a large drift project with many tables or
views being split across different files:

```
lib/src/database/
├── database.dart
├── tables/
│   ├── users.drift
│   ├── settings.drift
│   ├── groups.drift
│   └── search.drift
└── views/
    ├── friends.drift
    └── categories.dart
```

While a modular structure (with `import`s in drift files) is helpful to structure
sources, drift still generates everything into a single `database.g.dart` file.
With a growing number of tables and queries, drift may need to generate tens of
thousands of lines of code for data classes, companions and query results.

With its modular generation mode, drift instead generates sources for each input
file, like this:

```
lib/src/database/
├── database.dart
├── database.drift.dart
├── tables/
│   ├── users.drift
│   ├── users.drift.dart
│   ├── settings.drift
│   ├── settings.drift.dart
│   └── ...
└── views/
    ├── friends.drift
    ├── friends.drift.dart
    ├── categories.dart
    └── categories.drift.dart
```

### Enabling modular code generation

_Note_: A small example using modular code generation is also part of [drift's repository](https://github.com/simolus3/drift/tree/develop/examples/modular).

As drift's modular code generation mode generates different file patterns than
the default builder, it needs to be enabled explicitly. For this, create a
`build.yaml` file in which you disable the default `drift_dev` build and enable
the two builders for modular generation: `drift_dev:analyzer` and
`drift_dev:modular`. They should both get the same options:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        # disable drift's default builder, we're using the modular setup
        # instead.
        enabled: false

      # Instead, enable drift_dev:analyzer and drift_dev:modular manually:
      drift_dev:analyzer:
        enabled: true
        options: &options
          # Drift build options, as per https://drift.simonbinder.eu/docs/advanced-features/builder_options/
          store_date_time_values_as_text: true
          named_parameters: true
          sql:
            dialect: sqlite
            options:
              version: "3.39"
              modules: [fts5]
      drift_dev:modular:
        enabled: true
        # We use yaml anchors to give the two builders the same options
        options: *options
```

### What gets generated

With modular generation, drift generates standalone Dart libraries (Dart files
without a `part of` statement). This also means that you no longer need `part`
statements in your sources. Instead, you import the generated `.drift.dart`
files.

When it comes to using the generated code, not much is different: The API for
the database and DAOs stays mostly the same.
A big exception are how `.drift` files are handled in the modular generation
mode. In the default builder, all queries in all drift files are generated as
methods on the database.
With modular code generation, drift generates an implicit database accessor
reachable through getters from the database class. Consider a file `user.drift`
like this:

```sql
CREATE TABLE users (
  id INTEGER NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  name TEXT NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE
);

findUsers($predicate = TRUE): SELECT * FROM users WHERE $predicate;
```

If such a `users.drift` file is included from a database, we no longer generate
a `findUsers` method for the database itself.
Instead, a `users.drift.dart` file contains a [database accessor]({{ '../Dart API/daos.md' | pageUrl }}) called `UsersDrift` which is implicitly added to the database.
To call `findUsers`, you'd now call `database.usersDrift.findUsers()`.
