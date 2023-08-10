---
data:
  title: Getting started
  description: Simple guide to get a drift project up and running.
  weight: 1
  hide_section_index: true
template: layouts/docs/list
aliases:
  - /getting-started/  # Used to have this url
---

In addition to this document, other resources on how to use drift also exist.
For instance, [this playlist](https://www.youtube.com/watch?v=8ESbEFC0z5Y&list=PLztm2TugcV9Tn6J_H5mtxYIBN40uMAZgO)
or [this older video by Reso Coder](https://www.youtube.com/watch?v=zpWsedYMczM&t=281s) might be for you
if you prefer a tutorial video.

If you want to look at an example app instead, a cross-platform Flutter app using drift is available
[as part of the drift repository](https://github.com/simolus3/drift/tree/develop/examples/app).

## Project setup

{% include "partials/dependencies" %}

{% assign snippets = 'package:drift_docs/snippets/tables/filename.dart.excerpt.json' | readString | json_decode %}

### Declaring tables

Using drift, you can model the structure of your tables with simple dart code.
Let's write a file (simply called `filename.dart` in this snippet) containing
two simple tables and a database class using drift to get started:

{% include "blocks/snippet" snippets = snippets name = "overview" %}

__⚠️ Note:__ The column definitions, the table name and the primary key must be known at
compile time. For column definitions and the primary key, the function must use the `=>`
operator and can't contain anything more than what's included in the documentation and the
examples. Otherwise, the generator won't be able to know what's going on.

## Generating the code

Drift integrates with Dart's `build` system, so you can generate all the code needed with
`dart run build_runner build`. If you want to continuously rebuild the generated code
where you change your code, run `dart run build_runner watch` instead.
After running either command, drift's generator will have created the following classes for
you:

1. The `_$MyDatabase` class that your database is defined to extend. It provides access to all
   tables and core drift APIs.
2. A data class, `Todo` (for `Todos`) and `Category` (for `Categories`) for each table. It is
   used to hold the result of selecting rows from the table.
3. A class which drift calls a "companion" class (`TodosCompanion` and `CategoriesCompanion`
   in this example here).
   These classes are used to write inserts and updates into the table. These classes make drift
   a great match for Dart's null safety feature: In a data class, columns (including those using
   auto-incremented integers) can be non-nullable since they're coming from a select.
   Since you don't know the value before running an insert though, the companion class makes these
   columns optional.

With the generated code in place, the database can be opened by passing a connection to the superclass,
like this:

{% include "blocks/snippet" snippets = snippets name = "open" %}

That's it! You can now use drift by creating an instance of `MyDatabase`.
In a simple app from a `main` entrypoint, this may look like the following:

{% include "blocks/snippet" snippets = snippets name = "usage" %}

The articles linked below explain how to use the database in actual, complete
Flutter apps.
A complete example for a Flutter app using drift is also available [here](https://github.com/simolus3/drift/tree/develop/examples/app).

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
- You can use the same drift database on multiple isolates concurrently - see [Isolates]({{ '../Advanced Features/isolates.md' | pageUrl }}) for more on that.
- Drift has excellent support for custom SQL statements, including a static analyzer and code-generation tools. See [Getting started with sql]({{ 'starting_with_sql.md' | pageUrl }})
  or [Using SQL]({{ '../Using SQL/index.md' | pageUrl }}) for everything there is to know about using drift's SQL-based APIs.
- Something to keep in mind for later: When you change the schema of your database and write migrations, drift can help you make sure they're
  correct. Use [runtime checks], which don't require additional setup, or more involved [test utilities] if you want to test migrations between
  any schema versions.

[runtime checks]: {{ '../Advanced Features/migrations.md#verifying-a-database-schema-at-runtime' | pageUrl }}
[test utilities]: {{ '../Advanced Features/migrations.md#verifying-migrations' | pageUrl }}
