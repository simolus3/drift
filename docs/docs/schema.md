---

title: Tables
description: Define the schema of your database.

---

# Tables

A table in Drift represents a single entity or concept in your database. It defines the structure and behavior of the data you're storing.

The Basics:

- Each table is defined as a Dart class that extends `Table`.
- Columns are defined as fields in the table class.
- Each column must end with an extra pair of parentheses. Drift will warn you if you forget them.
- Name your tables in plural form (e.g., `Superheroes`, `Products`).

Tables are defined as classes that extend `Table`.
Columns are then defined as `late final` fields with one of the built-in [column types](#column-types).

## Quick example


Example:
<div class="annotate" markdown>
{{ load_snippet('simple_schema','lib/snippets/schema.dart.excerpt.json') }}
</div>
1. Each column must end with an extra pair of parentheses.   
    Drift will warn you if you forget them.  
    ```dart
    late final id = integer(); // Bad
    late final id = integer()(); // Good
    ```
2. By default, all columns are required. Use `nullable()` to make a column optional.

`name`, `age`, and `id` are fields of the model. Each column is specified as a `late final` field of the class.

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

## Using tables

Once you have defined your tables, you need to include them in your database. This is done by adding them to the `tables` list of the `@DriftDatabase` annotation.

{{ load_snippet('simple_schema_db','lib/snippets/schema.dart.excerpt.json') }}

When you add a new table, you need to run the code generation again to update the database.

```shell
dart run build_runner build
```

## Creating tables

Drift will create the tables automatically when initializing a new database. 
Subsequent changes to the schema require a migration. See the [Migration Guide](./guides/migrations.md) for more information.

---

## Columns

The most important part of a table is the list of columns. Columns are defined as fields in the table class.

Example:

{{ load_snippet('schema','lib/snippets/schema.dart.excerpt.json') }}

### Column types

Each column in you table should an instance of the appropriate column type. Drift provides a number of built-in column types to cover most use cases.

| Dart Type                        | Drift Column                          | SQL Type                                                |
| -------------------------------- | ------------------------------------- | ------------------------------------------------------- |
| `int`                            | `late final id = integer()()`         | `INTEGER`                                               |
| [`BigInt`](#int--bigint-columns) | `late final atoms = int64()()`        | `INTEGER`                                               |
| `String`                         | `late final name = text()()`          | `TEXT`                                                  |
| `bool`                           | `late final isAdmin = boolean()()`    | `INTEGER` (`1` or `0`)                                  |
| `double`                         | `late final height = real()()`        | `REAL`                                                  |
| `Uint8List`                      | `late final image = blob()()`         | `BLOB`                                                  |
| [`DateTime`](#datetime-columns)  | `late final createdAt = dateTime()()` | `INTEGER`or `TEXT` [More details...](#datetime-columns) |

In addition to these basic types, column can be configured to store any type which can be converted to a built-in type. See [Custom Types](#custom-types) for more information.

---


### Column options

Columns can be customized with a number of options. These options are available on all column types:


####  `nullable()`:
:    If this is called on a column, it will be allowed to store `null` values. By default, all columns are required.
    
    {{ load_snippet('optional_columns','lib/snippets/schema.dart.excerpt.json') }}

#### `withDefault()`:  
:    Set a default value as a SQL expression that is applied in the database itself.  Changing the default value requires a database migration. See [Expressions](./dart_api/expressions.md) for more information.

    {{ load_snippet('db_default','lib/snippets/schema.dart.excerpt.json') }}

#### `clientDefault()`:  
:    This sets a default value that is applied in your Dart code. Adding, removing, or changing the default value does not require a database migration.(1)
    { .annotate }

    1. Because this default value is only applied in your Dart code, it is not applied when interacting with the database outside of Drift.

    {{ load_snippet('client_default','lib/snippets/schema.dart.excerpt.json') }}

    !!! tip ""
        `clientDefault` is recommended over ``withDefault()` for most use cases as it offers more flexibility and does not require a database migration.

####  `unique()`:
:   If this is called on a column, it will enforce that all values in this column are unique.

    {{ load_snippet('unique_columns','lib/snippets/schema.dart.excerpt.json') }}

#### `check()`:
:   Adds a check constraint to the column. If this expression evaluates to `false`, an exception will be thrown when inserting or updating a record. See [Expressions](./dart_api/expressions.md) for more information.

    <div class="annotate" markdown>
    {{ load_snippet('check_column','lib/snippets/schema.dart.excerpt.json') }}
    </div>

    !!! note ""
        You must explicitly define types for columns referenced in a check. As in the example above, the `age` column is explicitly defined as an `Column<int>`.

#### `named()`:
:   Set the name of the column in the database. 

    {{ load_snippet('named_column','lib/snippets/schema.dart.excerpt.json') }}

    If `named()` is not used, the column name defaults to the field name in `snake_case`.

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

#### `generatedAs()`:
:   Set the column to be generated by the database. This is useful for columns which are calculated based on other columns in the table.

    === "Virtual Generated Columns (Default)"
        By default, generated columns are virtual, meaning they are not stored in the database. They are calculated on the fly when queried.

        {{ load_snippet('generated_column','lib/snippets/schema.dart.excerpt.json') }}

    === "Stored Generated Columns"

        Setting `stored` to `true` will store the generated value in the database. This can be useful for performance reasons, as the value does not need to be recalculated each time it is queried.

        {{ load_snippet('generated_column_stored','lib/snippets/schema.dart.excerpt.json') }}

    



## Primary Key

Every table in a database should have a primary key - a column or set of columns that uniquely identifies each row. Here's how to define primary keys in Drift:

1. **Auto-incrementing Primary Key (Recommended)**

    For most tables, a single auto-incrementing column is the simplest and most common primary key. Drift will use it as the primary key if one is defined:

    {{ load_snippet('pk-example','lib/snippets/schema.dart.excerpt.json') }}

    In this example, `id` will be automatically set as the primary key.

    !!! tip "Mixin Helper"

        Defining the same column for multiple tables can be tedious.  
        Consider using a [Mixin](#reusable-mixins) to reuse common columns.

2. **Custom Primary Key**

    If you need a different column (or set of columns) as the primary key, override the `primaryKey` getter in your table class:

    {{ load_snippet('custom_pk','lib/snippets/schema.dart.excerpt.json') }}

    This above would set the `email` column as the primary key.

!!! warning "Always Define a Primary Key"
    It is crucial to define a primary key for your tables. If you don't, a hidden `rowid` column will be created as the primary key in SQLite. This can lead to unexpected behavior.  

---


---

## Required Columns

By default, all columns are required. To make a column optional, use the `nullable()` method.

Example:




---

## Default Values

Drift offers two ways to set default values for columns:

#### 1. `clientDefault()` (Recommended)

`clientDefault()` sets a default value that is applied in your Dart code, offering more flexibility:

- You can change the default value without requiring a database migration. 
- This method also allows for dynamic values. See the example below.
- This default value is not applied when interacting with the database outside of Drift.
 

#### Example:   

Set the default dark mode setting based on the user's system settings.



#### 2. `withDefault()`

`withDefault()` sets the default value in the table schema itself. This has the following implications:

- Changing the default value requires a database migration. 
- Default value is always applied, even when connecting to the database without Drift.

#### Example:   

Set the default value for the `isAdmin` field to `false` if no value is provided.



---

## Unique Columns

To ensure that a column can only contain unique values, use the `unique` method.

{{ load_snippet('unique_columns','lib/snippets/schema.dart.excerpt.json') }}

Now, if another record with the same `name` is inserted, an exception will be thrown.

### Multi-Column Uniqueness

You can also enforce uniqueness across multiple columns by overriding the `uniqueKeys` getter in your table class.

#### Example:

Ensure that a table is only reserved once at a time. You can enforce this by making the combination of `time` and `table` unique.

{{ load_snippet('unique-table','lib/snippets/schema.dart.excerpt.json') }}

Now, if we try to create a record with the same `time` and `table`, an exception will be thrown.

---

## `DateTime` Columns

Drift simplifies the handling of `DateTime` objects, allowing you to use them directly in your Dart code while managing the conversion to the appropriate database format.

{{ load_snippet('datetime','lib/snippets/schema.dart.excerpt.json') }}

Drift offers two storage methods for `DateTime` objects:

1. Unix Timestamps (integers): The default method, offering faster performance but limited to second-level precision and lacking timezone information.
2. ISO-8601 Strings (text): Recommended for most applications due to its higher precision, timezone awareness, and human-readable format.

While Drift uses Unix timestamps by default for backward compatibility, we suggest using ISO-8601 strings for new projects. To enable this, adjust the `store_date_time_values_as_text` option in your `build.yaml` file:

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

### Switching Storage Methods

Switching between storage methods requires a database migration.

For detailed information on migrating between DateTime storage methods, please refer to our comprehensive [DateTime storage migration guide](./guides/datetime-migration.md).

---

## Enums

Drift provides support for storing Dart enums in your database. Enums can be stored either as integers (using their index) or as strings (using their name).

{{ load_snippet('enum','lib/snippets/schema.dart.excerpt.json') }}

!!! warning "Cautious Use of Enums"
    While enums offer convenience, they require careful consideration in database schemas:

    1. **Changing Enum Order**: If you use `intEnum`, adding, removing, or reordering enum values can break existing data. The integer stored in the database may no longer correspond to the correct enum value.

    2. **Renaming Enum Values**: If you use `textEnum`, renaming an enum value will make it impossible to read existing data for that value.

---

## Custom Types

Any Dart type can be stored in the database by converting it to one of the built-in types.

For example, if we wanted to store the built-in `Duration` type, we could convert it to an `int` before storing it. We'll create a custom converter for this.

<div class="annotate" markdown>

{{ load_snippet('converter','lib/snippets/schema.dart.excerpt.json') }}

</div>

1. Dart type we want to convert store.  
    In this case, we are storing `Duration`.
2. Built-in type we are converting to.
    In this case, we are converting `Duration` to `int`.

Then use the `.map()` method to add the converter to the column.

{{ load_snippet('apply_converter','lib/snippets/schema.dart.excerpt.json') }}

Now we can use the `Duration` type as if it were a built-in type.

{{ load_snippet('use_converter','lib/snippets/schema.dart.excerpt.json') }}

!!! warning "Implement Equality for Custom Types"

    Custom types should implement `==` and `hashCode` for correct equality comparisons. If you don't implement these, you won't be able to compare generated data classes reliably.

    Consider using a package like `equatable`, `freezed` or `dart_mappable` to create classes which implement this automatically.


### JSON Serializable Types

Drift offers a convenient way to store JSON serializable types using `TypeConverter.json()`.

{{ load_snippet('json_converter','lib/snippets/schema.dart.excerpt.json') }}

??? example "`Preferences` Class"

    {{ load_snippet('jsonserializable_type','lib/snippets/schema.dart.excerpt.json') }}

This converter will be used for:

[](){ #json1}
1. Converting between the Dart type and the SQL type when storing or retrieving data.  
[](){ #json2}
2. Converting between the Dart type and a JSON type when serializing and deserializing data.

<h3>Different Converters for SQL and JSON</h3>


It's also possible to use a different converter for [#1](#json1) and [#2](#json2) by creating a custom `TypeConverter` that mixes in `JsonTypeConverter2` with a third type parameter for the JSON type.

**Example:**

Convert `Preferences` to a string when storing in the database, but convert to a `Map<String, Object?>` when serializing to JSON.

<div class="annotate" markdown>

{{ load_snippet('custom_json_converter','lib/snippets/schema.dart.excerpt.json') }}

</div>

1. The `Preferences` type is converted to a string when storing in the database.
2. The `Preferences` type is converted to a `Map<String, Object?>` when serializing to JSON.


---

## Naming Customization

### Table & Column Name

By default, Drift uses `snake_case` for table and column names in the database. For example, a `TodoItems` table becomes `todo_items`, and an `emailAddress` column becomes `email_address`.

This conversion can be customized by setting the `case_from_dart_to_sql` option in your `build.yaml` file.



#### Custom Names

If you prefer to use a custom name for a table or column, you can override the default naming behavior:

- To customize the table name, override the `tableName` getter in your table class.
- To customize column names, use the `named()` method when defining the column.

Here's an example demonstrating these techniques:

{{ load_snippet('custom_table_name','lib/snippets/schema.dart.excerpt.json') }}

---

## Advanced

### Reusable Mixins

Drift allows you to reuse column definitions across multiple tables. This is particularly useful for common fields like `id` and `created_at`. Here's how you can define these columns once and reuse them:

{{ load_snippet('table_mixin','lib/snippets/schema.dart.excerpt.json') }}

The `Posts` table will have the `id` and `created_at` in addition to its own columns.

---

### Custom Constraints

Drift supports adding custom SQL constraints to your tables and columns. 

#### Column Constraints

To add a custom constraint to a column, use the `customConstraint` method.

{{ load_snippet('custom_column_constraint','lib/snippets/schema.dart.excerpt.json') }}

!!! warning "Custom Constraints remove `NOT NULL`"

    Adding `customConstraint` overrides any default constraints, including the `NOT NULL` constraint. To maintain the `NOT NULL` constraint while adding a custom constraint, explicitly include it in your `customConstraint` string.  
    
    Example:

    {{ load_snippet('custom_column_constraint_not_nullable','lib/snippets/schema.dart.excerpt.json') }}


#### Table Constraints
You can also add custom constraints to the table itself by overriding the `tableConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/schema.dart.excerpt.json') }}

!!! note "SQL Validation"

    Don't worry about syntax errors or unsupported features. Drift will validate the SQL you provide and throw an error during code generation if there are any issues.

---

### Custom Checks

Drift supports using expressions to check the validity of data in a column. This check is stored in the database, so if you change this check you will need to migrate the database.

Example:

<div class="annotate" markdown>

{{ load_snippet('custom-check','lib/snippets/schema.dart.excerpt.json') }}

</div>
1. When using a check you must define the type of the column explicitly.

If any record is inserted with an `age` less than `0`, an exception will be thrown.

See the [expression](./dart_api/expressions.md) documentation on how to write expressions.

---

### `BigInt` Columns

Use the standard `int` type for storing integers as it is efficient for typical values. Only use `BigInt` for extremely large numbers(1) when compiling to JavaScript, as it ensures accuracy but has a performance cost. For more information on how Dart handles numbers in JavaScript, see the official Dart [documentation](https://dart.dev/guides/language/numbers#what-should-you-do).
{ .annotate }

1. Like bigger than 4,503,599,627,370,496!

#### Migrating from/to `BigInt`

Drift uses an `INTEGER` column under the hood for both `int` and `BigInt` columns, so migrations are not required when switching between these types. The change only affects how Dart handles the values in your application code.




