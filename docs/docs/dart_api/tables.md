---

title: Tables
description: Define the schema of your database.

---

# Tables

In Drift, a table is the fundamental building block for organizing your database. It encapsulates a specific entity or concept, defining both the structure and behavior of your stored data.

The Basics:

- Each table is defined as a Dart class that extends `Table`.
- Columns are defined as `late final` fields with one of the built-in [column types](#column-types).
- Tables are included in the database by adding them to the `tables` list in the `@DriftDatabase` annotation.

## Quick example

<div class="annotate" markdown>
{{ load_snippet('simple_schema','lib/snippets/dart_api/tables.dart.excerpt.json') }}
</div>
1. Each column must end with an extra pair of parentheses.   
    Drift will warn you if you forget them.  
    ```dart
    late final id = integer(); // Bad
    late final id = integer()(); // Good
    ```
2. By default, all columns are required. Use `nullable()` to make a column optional.

`name`, `age`, and `id` are columns on this table.

The above `Persons` table would create a table with the following schema:

```sql
CREATE TABLE persons (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  age INTEGER,
)
```
Some technical notes:

- The name of the table, `persons` is automatically derived from the class name. This can be customized by overriding the `tableName` getter. See [Table Names](#table-name) for more information.
- The `id` column is automatically set as the primary key because it is an auto-incrementing integer. See [Primary Key](#primary-key) for more information.


---

## Adding tables

Add tables to your database by adding them to `@DriftDatabase` annotation.

{{ load_snippet('simple_schema_db','lib/snippets/dart_api/tables.dart.excerpt.json') }}

When you add a new table, you must rerun the code generation.

```bash
dart run build_runner build
```

On the first run, Drift initializes a brand-new database with all defined tables. However, if a database already exists, Drift won't make any automatic changes to its structure.

For existing databases, any schema modifications (like adding or removing tables and columns) require writing a [migration](../Migrations/index.md).

---



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

---


## Column options

Columns can be customized with several options. These options are available on all column types:


####  `nullable()`:
:    If this is called on a column, it can store `null` values. Otherwise, creating a row without a value for this column will throw an exception.

    **Example:**

    Creating a record without a value for `age` will throw an exception.
    
    {{ load_snippet('optional_columns','lib/snippets/dart_api/tables.dart.excerpt.json') }}

#### `withDefault()`:  
:    Set a default value as a SQL expression that is applied in the database itself. See [Expressions](./dart_api/expressions.md) for more information on how to write expressions. Adding, removing, or changing the default requires a database migration.

    **Example:**

    Setting a default value for `isAdmin ` to `false`:

    {{ load_snippet('db_default','lib/snippets/dart_api/tables.dart.excerpt.json') }}

#### `clientDefault()`:  
:    Sets a default value that is applied in your Dart code. Adding, removing, or changing the default value does not require a database migration.(1)
    { .annotate }

    1. Because this default value is only applied in your Dart code, it is not applied when interacting with the database outside of Drift.

    **Example:**

    Setting a default value for `isAdmin ` to `false`:

    {{ load_snippet('client_default','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    !!! tip "Recommended"
          `clientDefault` is recommended over `withDefault()` for most use cases as it offers more flexibility and does not require a database migration.

####  `unique()`:
:   If this is called on a column, it will enforce that all values in this column are unique.  
    To use a combination of columns unique, see [Multi-Column Uniqueness](#multi-column-uniqueness).

    **Example:**

    Don't allow two users to have the same `username`.

    {{ load_snippet('unique_columns','lib/snippets/dart_api/tables.dart.excerpt.json') }}


#### `check()`:
:   Adds a check constraint to the column. If this expression evaluates to `false` when creating or updating a row, an exception will be thrown. See [Expressions](./dart_api/expressions.md) for more information on how to write expressions.

    !!! warning "Check Constraints and Migrations"
        Migrations will fail if the check constraint is not met for existing data. Ensure that the check constraint is compatible with existing data before adding it.

    **Example:**

    Ensure that the `age` is greater than or equal to `0`.

    {{ load_snippet('check_column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    !!! note "Note"
        You must explicitly define types for columns referenced in a check. As in the example above, the `age` column is explicitly defined as a `Column<int>`.


    

#### `named()`:
:   Set the name of the column in the database explicitly. Otherwise, the column name will be the field name in `snake_case`.

    **Example:**

    Set the column name to be `created` instead of `created_at`.

    {{ load_snippet('named_column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    

    ??? note "Alternative Casing"
        In addition to `snake_case`, Drift supports the following casing options:

        - `preserve`
        - `camelCase`
        - `CONSTANT_CASE`
        - `PascalCase`
        - `lowercase`
        - `UPPERCASE`

        Customize this by setting the `case_from_dart_to_sql` option in your `build.yaml` file.     
        
        ```yaml
        targets:
          $default:
            builders:
              drift_dev:
                options:
                  case_from_dart_to_sql : snake_case # default
        ```

---

#### Integer Columns:

 `autoIncrement()`
:   If this is called on an `int` or `BigInt` column:

    - The column will be auto-incremented when inserting new records.
    - The column will be set as the primary key if no primary key is defined.

    {{ load_snippet('autoIncrement','lib/snippets/dart_api/tables.dart.excerpt.json') }}


#### Text Columns:
 `withLength()` 
:   Set the minimum and/or maximum length of a text column. This check is performed in Dart, changing this value does not require a migration.

    !!! warning "Existing Data"
        While migrations are not required to change the length of a text column, it is important to consider existing data.

        If a column is already populated with data which does not meet the length requirements, an exception will be thrown when Drift tries to read the data.

    **Example:**

    Ensure that the `name` is not an empty string and is less than 50 characters long.
  
    {{ load_snippet('withLength','lib/snippets/dart_api/tables.dart.excerpt.json') }}


---


## Primary keys

Every table in a database should have a primary key - a column or set of columns that uniquely identifies each row. 

1. **Auto-incrementing primary key (Recommended)**

    It's recommended to use an auto-incrementing integer as the primary key. 

    {{ load_snippet('pk-example','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    In this example, `id` will be automatically set as the primary key.

    !!! tip "Mixin Helper"

        Reuse column definitions across tables for common fields like `id` and `created_at`:

        {{ load_snippet('table_mixin','lib/snippets/dart_api/tables.dart.excerpt.json') }}

        The above `Posts` table will include the `id` and `createdAt` columns from the `TableMixin` mixin.

2. **Custom primary key**

    If you need a different column (or set of columns) as the primary key, override the `primaryKey` getter in your table class.

    - This it must be defined with the `=>` syntax, function bodies aren't supported.
    - It must return a set literal without collection elements like if, for or spread operators.

    {{ load_snippet('custom_pk','lib/snippets/dart_api/tables.dart.excerpt.json') }}

    This above would set the `email` column as the primary key.


!!! warning "Always Define a Primary Key"
    It is crucial to define a primary key for your tables. If you don't, a hidden `rowid` column will be created as the primary key in SQLite. This can lead to unexpected behavior.  


---


## Multi-column uniqueness

To enforce that a combination of columns is unique, override the `uniqueKeys` getter in your table class.

#### Example:

{{ load_snippet('unique-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The above example would enforce that the same table cant be reserved for the same date and time.

## References

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

## Generated columns
Use the `generatedAs` method to create a column which is calculated based on other columns in the table.

Drift supports two types of generated columns:

=== "Virtual (Default)"

    By default, a generated column is virtual. The value of a virtual column is calculated each time it is queried.
  
    {{ load_snippet('generated_column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

=== "Stored"

    Set the `stored` parameter to `true` to create a stored column. The value of a stored column is calculated once and stored in the database. This makes it faster to query but slower to write.

    {{ load_snippet('generated_column_stored','lib/snippets/dart_api/tables.dart.excerpt.json') }}
---

## `DateTime` storage

Drift offers two storage methods for `DateTime` objects:

1. Unix Timestamps (integers): The default method, offering faster performance but limited to second-level precision and lacking timezone information.
2. ISO-8601 Strings (text): Recommended for most applications due to its higher precision, timezone awareness, and human-readable format.

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

---

## Custom types

Any Dart type can be stored in the database by converting it to one of the built-in types.

Define a class which extends `TypeConverter` and implement the `toSql` and `fromSql` methods to convert between the Dart type and the type stored in the database.

Apply the converter to a column using the `.map()` method on the column.

#### Example:

<div class="annotate" markdown>

{{ load_snippet('converter','lib/snippets/dart_api/tables.dart.excerpt.json') }}

</div>

1. Dart type we want to convert store.  
    In this case, we are storing `Duration`.
2. Built-in type we are converting to.
    In this case, we are converting `Duration` to `int`.

{{ load_snippet('apply_converter','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Now we can use the `Duration` type as if it were a built-in type.

{{ load_snippet('use_converter','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! warning "Implement Equality for Custom Types"

    Custom types should implement `==` and `hashCode` for correct equality comparisons. If you don't implement these, you won't be able to compare generated data classes reliably.

    Consider using a package like `equatable`, `freezed` or `dart_mappable` to create classes which implement this automatically.

### JSON conversion

Drift offers a convenient way to store JSON serializable types using `TypeConverter.json()`.

**Example:**

{{ load_snippet('json_converter','lib/snippets/dart_api/tables.dart.excerpt.json') }}

??? example "`Preferences` Class"

    {{ load_snippet('jsonserializable_type','lib/snippets/dart_api/tables.dart.excerpt.json') }}



### Enums

Drift provides support for storing Dart enums in your database. Enums can be stored either as integers (using their index) or as strings (using their name).

{{ load_snippet('enum','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! warning "Cautious Use of Enums"
    While enums offer convenience, they require careful consideration in database schemas:

    1. **Changing Enum Order**: If you use `intEnum`, adding, removing, or reordering enum values can break existing data. The integer stored in the database may no longer correspond to the correct enum value.

    2. **Renaming Enum Values**: If you use `textEnum`, renaming an enum value will make it impossible to read existing data for that value.

---


## Table name

By default, Drift names tables in `snake_case` based on the class name. A table can be customized by overriding the `tableName` getter in your table class. 

{{ load_snippet('custom_table_name','lib/snippets/dart_api/tables.dart.excerpt.json') }}

---

## Indexes

Create an index using the `@TableIndex` annotation with the columns you want to index and a unique name to identify the index. The `unique` parameter can be set to `true` to enforce that all values in the indexed columns are unique.

To create more than one index on a table, add multiple `@TableIndex` annotations.

!!! question "What are indexes?"
    Indexes are a SQL feature that improves the speed of queries by creating a sorted list of values for one or more columns. This allows the database to quickly find the rows that match a query without having to scan the entire table.


**Example:**

These indexes will increase the speed of queries on the `Patients` table for the `name` and `age` columns.

{{ load_snippet('index','lib/snippets/dart_api/tables.dart.excerpt.json') }}


!!! note "Note"
    Indexes are automatically created for these columns and do not need to be defined manually.

    - Primary keys
    - Unique columns
    - Target column of a foreign key constraint
    
## Advanced

### Custom constraints

#### Column constraints

To add a custom constraint to a column, use the `customConstraint` method.

{{ load_snippet('custom_column_constraint','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! warning "Custom constraints replace Drift constraints"

    Adding `customConstraint` overrides any constraints added by Drift. Most notably, it removes the `NOT NULL` constraint. If you want to add a custom constraint and keep the column `NOT NULL`, you must add it manually.
    
    **Example:**

    {{ load_snippet('custom_column_constraint_not_nullable','lib/snippets/dart_api/tables.dart.excerpt.json') }}


#### Table constraints
You can also add custom constraints to the table itself by overriding the `tableConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

!!! note "SQL Validation"

    Don't worry about syntax errors or unsupported features. Drift will validate the SQL you provide and throw an error during code generation if there are any issues.


---

### `BigInt` columns

Use the standard `int` type for storing integers as it is efficient for typical values. Only use `BigInt` for extremely large numbers[^2] when compiling to JavaScript, as it ensures accuracy but has a performance cost. Switching between `int` and `BigInt` does not require a migration.

For more information on how Dart handles numbers in JavaScript, see the official Dart [documentation](https://dart.dev/guides/language/numbers).
{ .annotate }

[^2]: Like bigger than 4,503,599,627,370,496!
