---

title: Tables
description: Define the schema of your database.
---

As drift is a library built for relational databases, tables are the fundamental
building blocks for organizing your database.
They encapsulate a specific entry or concept, defining the structure of your
stored data.
For each table, drift generates a type-safe [row class](rows.md), allowing queries
and updates to be written as high-level Dart.
This page lists options available when declaring tables and columns.

## Defining tables

All tables defined with Drift share a common structure to define columns:

- Each table is defined as a Dart class that extends `Table`.
- In table classes, columns are defined as `late final` fields.
- The start of each field (like `integer()`) determines [the type](#column-types) of the column.

Let's take another look at the table defined in the [getting started](../setup.md)
example:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="simple_schema" />

Each column must end with an extra pair of parentheses.
Drift will warn you if you forget them.

Note that columns are non-nullable by default. Using `nullable()` allows storing `null` values.

This defines the `todo_items` table with columns `id`, `title`, `category`, and `created_at`.

The SQL equivalent of this table would be:

```sql
CREATE TABLE todo_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  created_at INTEGER -- Drift stores `dateTime()` columns as unix timestamps by default
);
```

Some technical notes:

- The name of the table, `todo_items` is automatically derived from the class name. This can be customized by overriding the `tableName` getter. See [Table Names](#changing-sql-names) for more information.
- The `id` column is automatically set as the primary key because it is an auto-incrementing integer. See [Primary Keys](#primary-keys) for more information.
- By default, `dateTime()` columns are stored as Unix timestamps. To store them as ISO-8601 strings, see [DateTime options](#datetime-options).

## Add to database

Add tables to your database by adding them to `@DriftDatabase` annotation.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="simple_schema_db" />

When you add a new table, you must run the code generator again:

```bash
dart run build_runner build
```
Drift initializes a brand-new database with all defined tables when the database is opened for the first time. (typically when running the app for the first time)

However, if a database already exists, Drift won't make any automatic changes to its structure. Please see [migrations](../migrations/index.md) for an overview of what to do when changing the database like this.


## Column types

Each column in a table has a fixed type describing the values it can store.
Drift offers a variety of built-in column types to suit most database needs.


| Dart Type                                                      | Drift Column                                      | SQL Type[^1]                |
| -------------------------------------------------------------- | ------------------------------------------------- | --------------------------- |
| `int`                                                          | `late final age = integer()()`                    | `INTEGER`                   |
| `BigInt` (as 64-bit, see [why](#when-to-use-bigint-and-int64)) | `late final age = int64()()`                      | `INTEGER`                   |
| `String`                                                       | `late final name = text()()`                      | `TEXT`                      |
| `bool`                                                         | `late final isAdmin = boolean()()`                | `INTEGER` (`1` or `0`)      |
| `double`                                                       | `late final height = real()()`                    | `REAL`                      |
| `Uint8List`                                                    | `late final image = blob()()`                     | `BLOB`                      |
| `DriftAny`                                                     | `late final value = sqliteAny()()`                | `ANY` (for `STRICT` tables) |
| `DateTime` (see [options](#datetime-options))                  | `late final createdAt = dateTime()()`             | `INTEGER`or `TEXT`          |
| Your own                                                       | See [type converter docs](../type_converters.md). | Depending on type           |
| Enums                                                          | [`intEnum` or `textEnum`](../type_converters.md#implicit-enum-converters). | `INTEGER` or `TEXT`         |
| Postgres Types                                                 | See [postgres docs](../platforms/postgres.md).    | Depending on type           |

In addition to these basic types, columns can be configured to store any type which can be converted to a built-in type. See [type converters](../type_converters.md) for more information.

[^1]: The SQL type is only used in the database. JSON serialization is not affected by the SQL type. For example, `bool` values are serialized as `true` or `false` in JSON, even though they are stored as `1` or `0` in the database.

## Primary keys

Every table in a database should have a primary key - a column or set of columns which uniquely identify each row.

#### Single auto-incrementing key

For most tables, a single auto-incrementing integer column is sufficient as the primary key.

With Drift, these columns are declared by using `autoIncrement()` in the definition of a column, which will:


1. Make that column the sole primary-key of the table.
   Thus, you can't use `autoIncrement()` on multiple columns, or mix
   `autoIncrement()` and other [primary keys](#primary-keys)
2. Make this column automatically count up by 1 for each new row.

For example, when declaring a table with an auto-incrementing column:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="autoIncrement" />

!!! tip "Tip: Sharing common columns with mixins"

    You can extract common column definitions that you might need in multiple tables
    into Dart mixins:

    <Snippet href="/lib/src/snippets/dart_api/tables.dart" name="table_mixin" />

    The above `Posts` table will include the `id` and `createdAt` columns from the `TableMixin` mixin.

#### Custom primary key

If you need a different column (or set of columns) as the primary key, override the `primaryKey` getter in your table class.

- It must be defined with the `=>` syntax, function bodies aren't supported.
- It must return a set literal without collection elements like if, for or spread operators.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="custom_pk" />

This above would set the `email` column as the primary key.

## Defining columns

In Drift, columns are declared with `late final` fields. The start of that field's value indicates
the [column's type](#column-types).
Additional modifiers are expressed with method calls refining that column.
Multiple modifiers can be applied to the same column by chaining method calls.

### Nullable columns

If this is called on a column, it will be able to store `null` values. For non-nullable columns,
drift will also mark relevant parameters as `required` when inserting rows:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="optional_columns" />

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
[schema change](../migrations/index.md) that requires special care.

A common example for default values is to add a column describing when the row has
been created:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="db_default" />

Despite being non-nullable, columns that have a default value are not `required`
for inserts, as the database will use the default as a fallback.

#### `clientDefault()`

Similarly to `withDefault()`, this sets a default value for columns.
Unlike `withDefault()` however, this value is computed in Dart instead of in
the database (1).
This means that adding, removing, or changing the default value does not require a database migration,
However, because this default value is only applied in your Dart code, it is not applied when interacting with the database outside of Drift.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="client_default" />

!!! tip "Recommended"
    `clientDefault` is recommended over `withDefault()` for most use cases as it offers more flexibility and does not require a database migration.

### References

[Foreign key references](https://www.sqlite.org/foreignkeys.html) can be expressed
in Dart tables with the `references()` method when building a column:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="references" />

The first parameter to `references` points to the table on which a reference should be created.
The second parameter is a [symbol](https://dart.dev/guides/language/language-tour#symbols) of the column to use for the reference.

Optionally, the `onUpdate` and `onDelete` parameters can be used to describe what
should happen when the target row gets updated or deleted.

Be aware that, in sqlite3, foreign key references aren't enabled by default.
They need to be enabled with `PRAGMA foreign_keys = ON`.
A suitable place to issue that pragma with drift is in a [post-migration callback](../migrations/index.md#post-migration-callbacks).


### Additional validation checks

Adds a check constraint to the column. If this expression evaluates to `false` when creating or updating a row, an exception will be thrown. See [Expressions](../dart_api/expressions.md) for more information on how to write expressions.

!!! warning "Check Constraints and Migrations"
    Migrations will fail if the check constraint is not met for existing data. Ensure that the check constraint is compatible with existing data before adding it.

#### Example

Ensure that the `age` is greater than or equal to `0`.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="check_column" />

!!! note "Note"
    To use type-specific expressions like `isBiggerOrEqualValue`, you must explicitly
    define the type of the column. In the example above, the `age` column is explicitly
    defined as a `Column<int>`.

### Constraining text length

Set the minimum and/or maximum length of a text column.
For legacy reasons, this check is performed in Dart (so changing the constraint does
not require a migration).
For stronger consistency checks, consider using a [check constraint](#additional-validation-checks) instead.

#### Example

Ensure that the `name` is not an empty and less than 50 characters long:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="withLength" />

### Generated columns

Use the `generatedAs` method to create a column which is calculated based on other columns in the table.

Matching most databases, supports both computed and stored generated columns:

<Tabs>

<TabItem label="Virtual (Default)" value="virtual">

By default, a generated column is virtual. The value of a virtual column is calculated each time it is queried.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="generated_column" />

</TabItem>

<TabItem label="Stored" value="stored">

Set the `stored` parameter to `true` to create a stored column. The value of a stored column is calculated once and then stored in the database.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="generated_column_stored" />

</TabItem>

</Tabs>

## Unique columns

Sometimes, columns might not be part of the primary key but are still known to hold unique
values.
This uniqueness can be enforced by including it in the schema, which can speed up some
queries.
To enforce that a single column is unique across all rows, use `unique()` as part of it's
definition:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="unique_columns" />

To enforce that a combination of columns is unique, override the `uniqueKeys` getter in your table class:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="unique-table" />

The above example would enforce that the same room can't be reserved twice on the
same day.

!!! tip "Not needed for primary keys"
    The primary key is already unique in each table, so you don't have to add a unique
    constraint for columns matching the primary key.

## Indexes

When a column that isn't a primary or unique is frequently used as a filter in a
`where` clause, [indexes](https://sqlite.org/lang_createindex.html) can be used to speed up these queries.
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

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="index" />

To specify the ordering mode for a column, you can use an `IndexedColumn` instance:

{{ load_snippet('index_ordering','lib/snippets/dart_api/tables.dart.excerpt.json') }}

#### SQL-based index

If you need more options in your index, for instance to define partial indexes,
you can also define your index with a direct SQL statement:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="indexsql" />

As you'd expect, drift will validate the `CREATE INDEX` statement at build time.

## Custom constraints

Drift provides dedicated APIs to express the most commonly used constraints and options that
can be applied to tables in SQL.
Tables constraints not directly supported can still be applied with snippets of SQL embedded
into Drift definitions.

### Custom column constraints

The typed column builder API covers most constraints to be set on columns.
If you need something more specific though, you can use the `customConstraint`
method to apply your own SQL constraints to the column:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="custom_column_constraint" />

!!! warning "Custom constraints replace Drift constraints"

    Adding `customConstraint` overrides any constraints added by Drift. Most notably, it removes the `NOT NULL` constraint. If you want to add a custom constraint and keep the column `NOT NULL`, you must add it manually.

    **Example:**

    <Snippet href="/lib/src/snippets/dart_api/tables.dart" name="custom_column_constraint_not_nullable" />

    Drift's builder will also emit a warning if you forget to include `NOT NULL`, or
    try to mix custom constraints with incompatible column options.

### Custom table constraints

You can also add custom constraints to the table itself by overriding the `tableConstraints` getter in your table class.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="custom-constraint-table" />

!!! success "SQL Validation"

    Don't worry about syntax errors or unsupported features. Drift will validate the SQL you provide and throw an error during code generation if there are any issues.

### `STRICT` and `WITHOUT ROWID` tables

SQLite supports a notion of ["strict"](https://www.sqlite.org/stricttables.html) tables where more
stringent type checking rules are applied to columns.
Drift does not currently enable this option by default, but might choose to do in a future major version.

Drift-defined tables can be made strict by overriding the `isStrict` getter:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="strict" />

Similarly, [`WITHOUT ROWID`](https://www.sqlite.org/withoutrowid.html) tables can be created by overriding
the `withoutRowId` getter.

## Advanced schema options

### Changing SQL names

By default, Drift translates Dart getter names to `snake_case` to determine the
name of a column to use in SQL.
For example, a column named `createdAt` in Dart would be named `created_at` in the
`CREATE TABLE` statement issued by drift.
By using `named()`, you can set the name of the column explicitly:

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="named_column" />

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

For tables, Drift names their name in SQL as the `snake_case` variant of the class name.
A table can be customized by overriding the `tableName` getter in your table class.

<Snippet href="/lib/src/snippets/dart_api/tables.dart" name="custom_table_name" />

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

See the [DateTime migration guide](../guides/datetime-migrations.md) for more information on how dates are stored and how to switch between storage methods.
