---
title: Tables
description: Tables are the fundamental building block for relational schemas. This page describes how to set them up with drift.
---

As drift is a library built for relational databases, tables are the fundamental
building blocks for organizing your database.
They encapsulate a specific entry or concept, defining the structure of your
stored data.

The Basics:

- Each table is defined as a Dart class that extends `Table`.
- Columns are defined as `late final` fields with one of the built-in [column types](#column-types).
- Tables are included in the database by adding them to the `tables` list in the `@DriftDatabase` annotation.

## Quick example

Let's take a deeper look at the tables defined in the [getting started]('getting-started.md')
example:

<div class="annotate" markdown>
{{ load_snippet('table','lib/snippets/setup/tables.dart.excerpt.json') }}
</div>
1. Each column must end with an extra pair of parentheses.
    Drift will warn you if you forget them.
    ```dart
    late final id = integer(); // Bad
    late final id = integer()(); // Good
    ```
2. By default, all columns are required. Use `nullable()` to make a column optional.

The above `TodoItems` table would create a table with the following schema:

```sql
CREATE TABLE todo_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT CHECK LENGTH(title) BETWEEN 6 AND 32,
  content TEXT,
  category INTEGER REFERENCES todo_category(id),
  created_at INTEGER
);
```

Note how the structure of the Dart class matches the created SQL statement.
Some technical notes:

- The name of the table, `todo_items` is automatically derived from the class name. This can be customized by overriding the `tableName` getter. See [Table Names](#table-name) for more information.
- The `id` column is automatically set as the primary key because it is an auto-incrementing integer. See [Primary Key](#primary-key) for more information.


## Adding tables

Add tables to your database by adding them to `@DriftDatabase` annotation.

{{ load_snippet('simple_schema_db','lib/snippets/setup/tables.dart.excerpt.json') }}

When you add a new table, you must re-run the code generator:

```bash
dart run build_runner build
```

When a database is first opened (typically when running the app for the first time),
Drift initializes a brand-new database with all defined tables. However, if a database already exists, Drift won't make any automatic changes to its structure. Please see [changing schemas](migrations.md) for an overview of what to do
when changing the database like this.

## Column types

Drift offers a variety of built-in column types to suit most database needs.


| Dart Type                        | Drift Column                          | SQL Type[^1]                                            |
| -------------------------------- | ------------------------------------- | ------------------------------------------------------- |
| `int`                            | `late final age = integer()()`        | `INTEGER`                                               |
| [`BigInt`](#int--bigint-columns) | `late final age = int64()()`          | `INTEGER`                                               |
| `String`                         | `late final name = text()()`          | `TEXT`                                                  |
| `bool`                           | `late final isAdmin = boolean()()`    | `INTEGER` (`1` or `0`)                                  |
| `double`                         | `late final height = real()()`        | `REAL`                                                  |
| `Uint8List`                      | `late final image = blob()()`         | `BLOB`                                                  |
| [`DateTime`](#datetime-columns)  | `late final createdAt = dateTime()()` | `INTEGER`or `TEXT` [More details...](#datetime-columns) |

In addition to these basic types, columns can be configured to store any type which can be converted to a built-in type. See [Custom Types](#custom-types) for more information.

[^1]: The SQL type is only used in the database. JSON serialization is not affected by the SQL type. For example, `bool` values are serialized as `true` or `false` in JSON, even though they are stored as `1` or `0` in the database.

## Column options

Columns can be customized with several options. These options are available on all column types:

####  `nullable()`:

If this is called on a column, it can store `null` values. For non-nullable columns,
drift will also mark relevant parameters as `required` when inserting rows:

{{ load_snippet('optional_columns','lib/snippets/setup/tables.dart.excerpt.json') }}

Without the `nullable()` call, `age` would be a required column.
Attempting to set this column to `null` in an existing row would throw an exception.

#### `withDefault()`:

Set a default value as a SQL expression that is applied in the database itself. See [expressions](../dart_api/expressions.md) for more information on how to write expressions. Adding, removing, or changing the default value is considered a
[schema change](migrations.md) that requires special care.

For example, we could set a default value for the content of todo items to
a placeholder:

{{ load_snippet('db_default','lib/snippets/setup/tables.dart.excerpt.json') }}

Despite being non-nullable, columns that have a default value are not `required`
for inserts, as the database will use the default as a fallback.

#### `clientDefault()`:

Similarly to `withDefault()`, this sets a default value for columns.
Unlike `withDefault()` however, this value is computed in Dart instead of in
the database (1).
This means that adding, removing, or changing the default value does not require a database migration:
{ .annotate }

1. Because this default value is only applied in your Dart code, it is not applied when interacting with the database outside of Drift.

{{ load_snippet('client_default','lib/snippets/setup/tables.dart.excerpt.json') }}

!!! tip "Recommended"
    `clientDefault` is recommended over `withDefault()` for most use cases as it offers more flexibility and does not require a database migration.

####  `unique()`:

If this is called on a column, every row in the table must have a unique value for
this column.
For example, this column

{{ load_snippet('unique_columns','lib/snippets/setup/tables.dart.excerpt.json') }}

To use a combination of columns unique, see [Multi-Column Uniqueness](#multi-column-uniqueness).

#### `check()`:
:   Adds a check constraint to the column. If this expression evaluates to `false` when creating or updating a row, an exception will be thrown. See [Expressions](./dart_api/expressions.md) for more information on how to write expressions.

    !!! warning "Check Constraints and Migrations"
        Migrations will fail if the check constraint is not met for existing data. Ensure that the check constraint is compatible with existing data before adding it.

    **Example:**

    Ensure that the `age` is greater than or equal to `0`.

    !!! note "Note"
        You must explicitly define types for columns referenced in a check. As in the example above, the `age` column is explicitly defined as a `Column<int>`.




#### `named()`:
:   Set the name of the column in the database explicitly. Otherwise, the column name will be the field name in `snake_case`.

    **Example:**

    Set the column name to be `created` instead of `created_at`.



    ??? note "Alternative Casing"
        In addition to `snake_case`, Drift supports the following casing options:

        - `preserve`
        - `camelCase`
        - `CONSTANT_CASE`
        - `PascalCase`
        - `lowercase`
        - `UPPERCASE`

        Customize this by setting the `case_from_dart_to_sql` option in your `build.yaml` file.

        ```yaml title="build.yaml"
        targets:
          $default:
            builders:
              drift_dev:
                options:
                  case_from_dart_to_sql : snake_case # default
        ```
