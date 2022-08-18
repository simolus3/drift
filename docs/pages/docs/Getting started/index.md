---
data:
  title: Getting started
  description: Simple guide to get a drift project up and running
  weight: 1
  hide_section_index: true
template: layouts/docs/list
aliases:
  - /getting-started/  # Used to have this url
---

_Note:_ If you prefer a tutorial video, Reso Coder has made a detailed video explaining
how to get started. You can watch it [here](https://youtu.be/zpWsedYMczM).

A complete cross-platform Flutter app using drift is also available [here](https://github.com/simolus3/drift/tree/develop/examples/app).

## Adding the dependency
First, lets add drift to your project's `pubspec.yaml`.
At the moment, the current version of `drift` is [![Drift version](https://img.shields.io/pub/v/drift.svg)](https://pub.dev/packages/drift)
and the latest version of `drift_dev` is [![Generator version](https://img.shields.io/pub/v/drift_dev.svg)](https://pub.dev/packages/drift_dev).

{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}
{% assign snippets = 'package:drift_docs/snippets/tables/filename.dart.excerpt.json' | readString | json_decode %}

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.0.0
  path: ^{{ versions.path }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

If you're wondering why so many packages are necessary, here's a quick overview over what each package does:

- `drift`: This is the core package defining most apis
- `sqlite3_flutter_libs`: Ships the latest `sqlite3` version with your Android or iOS app. This is not required when you're _not_ using Flutter,
  but then you need to take care of including `sqlite3` yourself.
  For an overview on other platforms, see [platforms]({{ '../platforms.md' | pageUrl }}).
- `path_provider` and `path`: Used to find a suitable location to store the database. Maintained by the Flutter and Dart team
- `drift_dev`: This development-only dependency generates query code based on your tables. It will not be included in your final app.
- `build_runner`: Common tool for code-generation, maintained by the Dart team

{% include "partials/changed_to_ffi" %}

### Declaring tables

Using drift, you can model the structure of your tables with simple dart code:

{% include "blocks/snippet" snippets = snippets name = "overview" %}

__⚠️ Note:__ The column definitions, the table name and the primary key must be known at
compile time. For column definitions and the primary key, the function must use the `=>`
operator and can't contain anything more than what's included in the documentation and the
examples. Otherwise, the generator won't be able to know what's going on.

## Generating the code
Drift integrates with Dart's `build` system, so you can generate all the code needed with 
`flutter pub run build_runner build`. If you want to continuously rebuild the generated code
where you change your code, run `flutter pub run build_runner watch` instead.
After running either command once, the drift generator will have created a class for your
database and data classes for your entities. To use it, change the `MyDatabase` class as
follows:

{% include "blocks/snippet" snippets = snippets name = "open" %}

## Next steps

Congratulations! You're now ready to use all of drift. See the articles below for further reading.
The ["Writing queries"]({{ "writing_queries.md" | pageUrl }}) article contains everything you need
to know to write selects, updates and inserts in drift!

{% block "blocks/alert" title="Using the database" %}
> The database class from this guide is ready to be used with your app.
  For Flutter apps, a Drift database class is typically instantiated at the top of your widget tree
  and then passed down with `provider` or `riverpod`.
  See [using the database]({{ '../faq.md#using-the-database' | pageUrl }}) for ideas on how to integrate
  Drift into your app's state management.

  The setup in this guide uses [platform channels](https://flutter.dev/docs/development/platform-integration/platform-channels),
  which are only available after running `runApp` by default.
  When using drift before your app is initialized, please call `WidgetsFlutterBinding.ensureInitialized()` before using
  the database to ensure that platform channels are ready.
{% endblock %}

- The articles on [writing queries]({{ 'writing_queries.md' | pageUrl }}) and [Dart tables]({{ 'advanced_dart_tables.md' | pageUrl }}) introduce important concepts of the Dart API used to write queries.
- The setup shown here uses the `sqlite3` package to run queries synchronously on the main isolate.
 With a bit of additional setup, drift can transparently run in a background isolate without
 you having to adapt your query code. See [Isolates]({{ '../Advanced Features/isolates.md' | pageUrl }}) for more on that.
- Drift has excellent support for custom SQL statements, including a static analyzer and code-generation tools. See [Getting started with sql]({{ 'starting_with_sql.md' | pageUrl }})
  or [Using SQL]({{ '../Using SQL/index.md' | pageUrl }}) for everything there is to know about using drift's SQL-based APIs.
- Something to keep in mind for later: When you change the schema of your database and write migrations, drift can help you make sure they're
  correct. Use [runtime checks], which don't require additional setup, or more involved [test utilities] if you want to test migrations between
  any schema versions.

[runtime checks]: {{ '../Advanced Features/migrations.md#verifying-a-database-schema-at-runtime' | pageUrl }}
[test utilities]: {{ '../Advanced Features/migrations.md#verifying-migrations' | pageUrl }}
