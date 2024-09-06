---
data:
  title: "Exporting schemas"
  weight: 10
  description: Store all schema versions of your app for validation.
template: layouts/docs/single
---

By design, drift's code generator can only see the current state of your database
schema. When you change it, it can be helpful to store a snapshot of the older
schema in a file.
Later, drift tools can take a look at all the schema files to validate the migrations
you write.

We recommend exporting the initial schema once. Afterwards, each changed schema version
(that is, every time you change the `schemaVersion` in the database) should also be
stored.
This guide assumes a top-level `drift_schemas/` folder in your project to store these
schema files, like this:

```
my_app
  .../
  lib/
    database/
      database.dart
      database.g.dart
  test/
    generated_migrations/
      schema.dart
      schema_v1.dart
      schema_v2.dart
  drift_schemas/
    drift_schema_v1.json
    drift_schema_v2.json
  pubspec.yaml
```

Of course, you can also use another folder or a subfolder somewhere if that suits your workflow
better.

{% block "blocks/alert" title="Examples available" %}
Exporting schemas and generating code for them can't be done with `build_runner` alone, which is
why this setup described here is necessary.

We hope it's worth it though! Verifying migrations can give you confidence that you won't run
into issues after changing your database.
If you get stuck along the way, don't hesitate to [open a discussion about it](https://github.com/simolus3/drift/discussions).

Also there are two examples in the drift repository which may be useful as a reference:

- A [Flutter app](https://github.com/simolus3/drift/tree/latest-release/examples/app)
- An [example specific to migrations](https://github.com/simolus3/drift/tree/latest-release/examples/migrations_example).
{% endblock %}

## Exporting the schema

To begin, lets create the first schema representation:

```
$ mkdir drift_schemas
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/
```

This instructs the generator to look at the database defined in `lib/database/database.dart` and extract
its schema into the new folder.

After making a change to your database schema, you can run the command again. For instance, let's say we
made a change to our tables and increased the `schemaVersion` to `2`. To dump the new schema, just run the
command again:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/
```

You'll need to run this command every time you change the schema of your database and increment the `schemaVersion`.

Drift will name the files in the folder `drift_schema_vX.json`, where `X` is the current `schemaVersion` of your
database.
If drift is unable to extract the version from your `schemaVersion` getter, provide the full path explicitly:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v3.json
```

{% block "blocks/alert" title='<i class="fas fa-lightbulb"></i> Dumping a database' color="success" %}
If, instead of exporting the schema of a database class, you want to export the schema of an existing sqlite3
database file, you can do that as well! `drift_dev schema dump` recognizes a sqlite3 database file as its first
argument and can extract the relevant schema from there.
{% endblock %}

## What now?

Having exported your schema versions into files like this, drift tools are able
to generate code aware of multiple schema versions.

This enables [step-by-step migrations]({{ 'step_by_step.md' | pageUrl }}): Drift
can generate boilerplate code for every schema migration you need to write, so that
you only need to fill in what has actually changed. This makes writing migrations
much easier.

By knowing all schema versions, drift can also [generate test code]({{'tests.md' | pageUrl}}),
which makes it easy to write unit tests for all your schema migrations.
