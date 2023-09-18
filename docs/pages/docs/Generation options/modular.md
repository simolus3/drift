---
data:
  title: "Modular code generation"
  description: Make drift generate code in multiple files.
template: layouts/docs/single
---

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

## Enabling modular code generation

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

## What gets generated

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
