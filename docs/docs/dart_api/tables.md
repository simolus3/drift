---

title: Tables
description: Define the schema of your database.
---

# Tables

As drift is a library built for relational databases, tables are the fundamental
building blocks for organizing your database.
They encapsulate a specific entry or concept, defining the structure of your
stored data.

The Basics:

- Each table is defined as a Dart class that extends `Table`.
- In table classes, columns are defined as `late final` fields with one of the built-in [column types](#column-types).
- Tables are included in the database by adding them to the `tables` list in the `@DriftDatabase` annotation.

## Quick example

Let's take another look at the tables defined in the [getting started]('getting-started.md')
example:

<div class="annotate" markdown>
{{ load_snippet('simple_schema','lib/snippets/dart_api/tables.dart.excerpt.json') }}
</div>
1. Each column must end with an extra pair of parentheses.
    Drift will warn you if you forget them.
    ```dart
    late final id = integer(); // Bad
    late final id = integer()(); // Good
    ```
2. Drift adopts the choice from Dart's type system to make columns non-nullable by default. Using `nullable()` allows storing `null` values.

`name`, `age`, and `id` are columns on this table.

The above `TodoItems` table would create a table with the following schema:

```sql
CREATE TABLE todo_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  content TEXT,
  category INTEGER REFERENCES todo_category(id),
  created_at INTEGER
);
```

Note how the structure of the Dart class matches the created SQL statement.
Some technical notes:

- The name of the table, `todo_items` is automatically derived from the class name. This can be customized by overriding the `tableName` getter. See [Table Names](#table-name) for more information.
- The `id` column is automatically set as the primary key because it is an auto-incrementing integer. See [Primary Keys](#primary-keys) for more information.

## Adding tables

Add tables to your database by adding them to `@DriftDatabase` annotation.

{{ load_snippet('simple_schema_db','lib/snippets/dart_api/tables.dart.excerpt.json') }}

When you add a new table, you must re-run the code generator:

```bash
dart run build_runner build
```

When a database is first opened (typically when running the app for the first time),
Drift initializes a brand-new database with all defined tables. However, if a database already exists, Drift won't make any automatic changes to its structure. Please see [migrations](../Migrations/index.md) for an overview of what to do
when changing the database like this.

## Column types

Each column in a table has a fixed type describing the values it can store.
Drift offers a variety of built-in column types to suit most database needs.


| Dart Type                        | Drift Column                          | SQL Type[^1]                                            |
| -------------------------------- | ------------------------------------- | ------------------------------------------------------- |
| `int`                            | `late final age = integer()()`        | `INTEGER`                                               |
| [`BigInt`](#when-to-use-bigint-and-int64) | `late final age = int64()()`          | `INTEGER`                                               |
| `String`                         | `late final name = text()()`          | `TEXT`                                                  |
| `bool`                           | `late final isAdmin = boolean()()`    | `INTEGER` (`1` or `0`)                                  |
| `double`                         | `late final height = real()()`        | `REAL`                                                  |
| `Uint8List`                      | `late final image = blob()()`         | `BLOB`                                                  |
| `DriftAny`                       | `late final value = sqliteAny()()`    | `ANY` (for `STRICT` tables)                             |
| [`DateTime`](#datetime-options)  | `late final createdAt = dateTime()()` | `INTEGER`or `TEXT` [More details...](#datetime-options) |
| Types specific to Postgres | See [postgres docs](../Platforms/postgres.md). | Depending on type. |

In addition to these basic types, columns can be configured to store any type which can be converted to a built-in type. See [type converters](../type_converters.md) for more information.

[^1]: The SQL type is only used in the database. JSON serialization is not affected by the SQL type. For example, `bool` values are serialized as `true` or `false` in JSON, even though they are stored as `1` or `0` in the database.

### When to use `BigInt` and `int64()`

In SQL, Drift's `integer()` and `int64()` types both map to a column type storing 64-bit
integers (`INTEGER` in SQLite).
This means that integer columns match the behavior of `int`s in native Dart.
When compiling to JavaScript however, we run into an issue: Large values can't exactly
be represented by JavaScript's only numeric type, 64-bit doubles.

So, for projects that need to be compiled to JavaScript _and_ store potentially large
numbers in integer columns, drift offers `int64()` which represents all numbers as
a `BigInt` in Dart, avoiding compatibility issues with JavaScript.

### `DateTime` options

Since SQLite doesn't have a dedicated type to store date and time values, Drift
offers two storage methods for `DateTime` objects:

1. Unix Timestamps: The column type for `dateTime()` columns in the database
   is `INTEGER` storing unix timestamps in seconds.
   No timezone information or sub-second accuracy is provided.
2. ISO-8601 Strings (recommended): Stores `dateTime()` columns as text.
  Recommended for most applications due to its higher precision and timezone
  awareness.

Drift uses Unix timestamps by default for backward compatibility reasons. However, we suggest using ISO-8601 strings for new projects. To enable this, adjust the `store_date_time_values_as_text` option in your `build.yaml` file:

```yaml title="build.yaml"
targets:
  $default:
    builders:
      drift_dev:
        options:
          store_date_time_values_as_text: false # (default)
          # To use ISO 8601 strings
          # store_date_time_values_as_text: true
```

See the [DateTime Guide](../guides/datetime-migrations.md) for more information on how dates are stored and how to switch between storage methods.

## Column constraints

Column constraints in SQL refine declared columns, for example by making a column
a reference to providing a default.
Most column constraints in SQL can be expressed directly when declaring the column
by calling methods on Drift's column builder:

### Auto-increment

_This option is only available on integer columns._

Using `autoIncrement()` when defining a column will:

1. Make that column the sole primary-key of the table
   (thus, you can't use `autoIncrement()` on multiple columns, or mix
   `autoIncrement`() and other [primary key](#primary-keys)).
2. Instruct the database to use an incrementing sequence as a default
   value for this column.

For example, when declaring a table with an auto-incrementing column:

{{ load_snippet('autoIncrement','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Values can be inserted without having to specify values for the column:

=== "Core"

    {{ load_snippet('autoIncrementUse','lib/snippets/dart_api/tables.dart.excerpt.json') }}

=== "Manager"

    {{ load_snippet('autoIncrementUseManager','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Nullable columns

If this is called on a column, it will be able to store `null` values. For non-nullable columns,
drift will also mark relevant parameters as `required` when inserting rows:

{{ load_snippet('optional_columns','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Without the `nullable()` call, `age` would be a required column.
Attempting to set this column to `null` in an existing row would throw an exception.

### Default values

Some columns aren't necessarily nullable, but still have a reasonable default
value that all new rows can share.
Instead of having to specify this value at every insert, it can be added to the
column.
Drift offers two ways to specify default values: `withDefault()` adds a `DEFAULT`
constraint to the column in the schema (this is also sometimes called "server default"
in other database frameworks). `clientDefault()` does not alter the schema, but instead
computes a default value in Dart that is implicitly added to Drift-generated insert
statements.

#### `withDefault()`

Set a default value as a SQL expression that is applied in the database itself. See [expressions](../dart_api/expressions.md) for more information on how to write these expressions. Adding, removing, or changing the default value is considered a
[schema change](../Migrations/index.md) that requires special care.

A common example for default values is to add a column describing when the row has
been created:

{{ load_snippet('db_default','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Despite being non-nullable, columns that have a default value are not `required`
for inserts, as the database will use the default as a fallback.

#### `clientDefault()`

Similarly to `withDefault()`, this sets a default value for columns.
Unlike `withDefault()` however, this value is computed in Dart instead of in
the database (1).
This means that adding, removing, or changing the default value does not require a database migration:
{ .annotate }

1. Because this default value is only applied in your Dart code, it is not applied when interacting with the database outside of Drift.

{{ load_snippet('client_default','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! tip "Recommended"
    `clientDefault` is recommended over `withDefault()` for most use cases as it offers more flexibility and does not require a database migration.

### References

[Foreign key references](https://www.sqlite.org/foreignkeys.html) can be expressed
in Dart tables with the `references()` method when building a column:

{{ load_snippet('references','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The first parameter to `references` points to the table on which a reference should be created.
The second parameter is a [symbol](https://dart.dev/guides/language/language-tour#symbols) of the column to use for the reference.

Optionally, the `onUpdate` and `onDelete` parameters can be used to describe what
should happen when the target row gets updated or deleted.

Be aware that, in sqlite3, foreign key references aren't enabled by default.
They need to be enabled with `PRAGMA foreign_keys = ON`.
A suitable place to issue that pragma with drift is in a [post-migration callback](../Migrations/index.md#post-migration-callbacks).

### Unique columns

If this is called on a column, every row in the table must have a unique value for
this column.
For example, this column

{{ load_snippet('unique_columns','lib/snippets/dart_api/tables.dart.excerpt.json') }}

To enforce that a combination of columns is unique, see [Multi-Column Uniqueness](#multi-column-uniqueness).


### Additional validation checks

Adds a check constraint to the column. If this expression evaluates to `false` when creating or updating a row, an exception will be thrown. See [Expressions](../dart_api/expressions.md) for more information on how to write expressions.

!!! warning "Check Constraints and Migrations"
    Migrations will fail if the check constraint is not met for existing data. Ensure that the check constraint is compatible with existing data before adding it.

#### Example

Ensure that the `age` is greater than or equal to `0`.

{{ load_snippet('named_column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! note "Note"
    To use type-specific expressions like `isBiggerOrEqualValue`, you must explicitly
    define the type of the column. In the example above, the `age` column is explicitly
    defined as a `Column<int>`.


### Column names

By default, drift translates Dart getter names to `snake_case` to determine the
name of a column to use in SQL.
For example, a column named `createdAt` in Dart would be named `created_at` in the
`CREATE TABLE` statement issued by drift.
By using `named()`, you can set the name of the column explicitly.

??? note "Only need alternative casing?"
    If you're only using `named()` to change the casing of the column used by
    Drift when translating Dart column names to SQL, you may want to use the
    global `case_from_dart_to_sql` [builder option](../generation_options/index.md) instead.
    In addition to `snake_case` (the default), Drift supports the following casing options:

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

### Constraining text length

Set the minimum and/or maximum length of a text column.
For legacy reasons, this check is performed in Dart (so changing the constraint does
not require a migration).
For stronger consistency checks, consider using a [check constraint](#additional-validation-checks) instead.

#### Example

Ensure that the `name` is not an empty and less than 50 characters long:

{{ load_snippet('withLength','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Generated columns

Use the `generatedAs` method to create a column which is calculated based on other columns in the table.

Matching most databases, supports both computed and stored generated columns:

=== "Virtual (Default)"

    By default, a generated column is virtual. The value of a virtual column is calculated each time it is queried.

    {{ load_snippet('generated_column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

=== "Stored"

    Set the `stored` parameter to `true` to create a stored column. The value of a stored column is calculated once and then stored in the database.

    {{ load_snippet('generated_column_stored','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Custom constraints

The typed column builder API covers most constraints to be set on columns.
If you need something more specific though, you can use the `customConstraint`
method to apply your own SQL constraints to the column:

{{ load_snippet('custom_column_constraint','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! warning "Custom constraints replace Drift constraints"

    Adding `customConstraint` overrides any constraints added by Drift. Most notably, it removes the `NOT NULL` constraint. If you want to add a custom constraint and keep the column `NOT NULL`, you must add it manually.

    **Example:**

    {{ load_snippet('custom_column_constraint_not_nullable','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    Drift's builder will also emit a warning if you forget to include `NOT NULL`, or
    try to mix custom constraints with incompatible column options.

## Table constraints

### Primary keys

Every table in a database should have a primary key - a column or set of columns that uniquely identifies each row.

#### Single auto-incrementing key

For most tables, a single auto-incrementing integer column can serve as a good primary
key:

{{ load_snippet('autoIncrement','lib/snippets/dart_api/tables.dart.excerpt.json') }}

In this example, `id` will be automatically set as the primary key.

!!! tip "Mixin Helper"

    You can extract common column definitions that you might need in multiple tables
    into Dart mixins:

    {{ load_snippet('table_mixin','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    The above `Posts` table will include the `id` and `createdAt` columns from the `TableMixin` mixin.

#### Custom primary key

If you need a different column (or set of columns) as the primary key, override the `primaryKey` getter in your table class.

- It must be defined with the `=>` syntax, function bodies aren't supported.
- It must return a set literal without collection elements like if, for or spread operators.

{{ load_snippet('custom_pk', 'lib/snippets/dart_api/tables.dart.excerpt.json') }}

This above would set the `email` column as the primary key.

### Multi-column uniqueness

To enforce that a combination of columns is unique, override the `uniqueKeys` getter in your table class.

!!! tip "Not needed for primary keys"
    The primary key is already unique in each table, so you don't have to add a unique
    constraint for columns matching the primary key.

#### Example

{{ load_snippet('unique-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The above example would enforce that the same room can't be reserved twice on the
same day.
Single columns can be made unique by including a single-element set in `uniqueKeys`,
but using the [unique](#unique-columns) column option is typically easier.

### Table name

By default, Drift names tables in `snake_case` based on the class name. A table can be customized by overriding the `tableName` getter in your table class.

{{ load_snippet('custom_table_name','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Custom table constraints

You can also add custom constraints to the table itself by overriding the `tableConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! note "SQL Validation"

    Don't worry about syntax errors or unsupported features. Drift will validate the SQL you provide and throw an error during code generation if there are any issues.


## Indexes

When a column that isn't a primary or unique is frequently used as a filter in a
`where` clause, indexes can be used to speed up these queries.
This is particularly true for large tables: Without an index, database engines
essentially have to loop through every row to find the ones matching your where clause.
For each index, a lookup structure mapping the index value to matching rows is created
and maintained behind the scenes.
This allows the database to quickly find the rows that match a query without having to scan the entire table.

Create an index using the `@TableIndex` annotation with the columns you want to index and a unique name to identify the index. The `unique` parameter can be set to `true` to enforce that all values in the indexed columns are unique.

To create more than one index on a table, add multiple `@TableIndex` annotations.

!!! note "Note"
    Indexes are automatically created for these columns and do not need to be defined manually.

    - Primary keys
    - Unique columns
    - Target column of a foreign key constraint

#### Example

This index will make queries based on the name of users more efficient if the
users table contains a lot of rows:

{{ load_snippet('index','lib/snippets/dart_api/tables.dart.excerpt.json') }}

#### SQL-based index

If you need more options in your index, for instance to define partial indexes,
you can also define your index with a direct SQL statement:

{{ load_snippet('indexsql','lib/snippets/dart_api/tables.dart.excerpt.json') }}

As you'd expect, drift will validate the `CREATE INDEX` statement at build time.
