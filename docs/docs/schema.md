---

title: Schema
description: Define the schema of your database.

---




## Dart or SQL

There are two primary methods to define your database schema when using Drift:

1. **Dart-based Schema Definition**: Define your schema using Dart classes and annotations. This method provides type safety and seamless integration with your Dart code.

2. **SQL-based Schema Definition**: Define your schema using SQL statements. This method offers direct database control while maintaining type safety and SQL validation.

This page primarily focuses on the Dart-based schema definition method. For detailed information on SQL-based schema definition, please refer to the [SQL](./sql.md) section of the documentation.

## Table Definition

Tables are defined as classes that extend `Table`. Columns are added as properties to the class.

{{ load_snippet('simple_schema','lib/snippets/schema.dart.excerpt.json') }}

This table is added to the database by listing it in the `tables` parameter of the `@DriftDatabase` annotation.

{{ load_snippet('simple_schema_db','lib/snippets/schema.dart.excerpt.json') }}


!!! tip "Table Name"

    Tables should be named in plural form (e.g., `Superheroes`, `Products`). This convention generally leads to more appropriately named generated classes. See the [name] section to customize ;dsfldinvl

## Primary Key

Every table in a database should have a primary key - a column or set of columns that uniquely identifies each row. Here's how to define primary keys in Drift:

1. **Auto-incrementing Primary Key (Recommended)**

    For most tables, a single auto-incrementing column is the simplest and most common primary key. Drift will use a auto-incrementing integer column as the primary key if one is defined:

    {{ load_snippet('pk-example','lib/snippets/schema.dart.excerpt.json') }}

    In this example, `id` will be automatically set as the primary key.

    !!! tip "Mixin Helper"

        Defining the same column over and over again can be tedious.  
        Consider using a [Mixin](#reusable-mixins) as a more convenient way reuse columns.

2. **Custom Primary Key**

    If you need a different column (or set of columns) as the primary key, override the `primaryKey` getter in your table class:

    {{ load_snippet('custom_pk','lib/snippets/schema.dart.excerpt.json') }}

    This sets the `email` column as the primary key.

!!! warning "Always Define a Primary Key"
    When using Drift with SQLite, always explicitly define a primary key for your tables. If you don't, SQLite automatically creates a hidden `rowid` column as the primary key, which can lead to unexpected behavior.

## Supported Column Types

Each column in your table should be defined as a `late final` field that uses one of the column types provided by Drift.

The following table lists the built-in column types:

| Dart Type                        | Drift Column                                  |
| -------------------------------- | --------------------------------------------- |
| `int`                            | `late final id = integer()()`                 |
| [`BigInt`](#int--bigint-columns) | `late final atoms = int64()()`                |
| `String`                         | `late final name = text()()`                  |
| `bool`                           | `late final isAdmin = boolean()()`            |
| `double`                         | `late final height = real()()`                |
| `Uint8List`                      | `late final image = blob()()`                 |
| [`DateTime`](#datetime-columns)  | `late final createdAt = dateTime()()`         |
| [`enum`](#enums)                 | `late final category = intEnum<Category>()()` |

!!! note "Extra Parentheses"  

    Each column must end with an extra pair of parentheses.  
    Drift will warn you if you forget them.  
      
      ```dart
      late final id = integer(); // Bad
      late final id = integer()(); // 
      ```

In addition to these built-in types, you can also store custom types by converting them to one of these built-in types. See the [Custom Types](#custom-types) section for more information.

## Required Columns

By default, all columns are required. To make a column optional, use the `nullable()` method.

Example:

{{ load_snippet('optional_columns','lib/snippets/schema.dart.excerpt.json') }}

Now the `age` column is optional. If you try to insert a record without an `age`, it will be set to `null`.

## Default Values

To set default values for your database fields, use the `clientDefault()` method.

{{ load_snippet('client_default','lib/snippets/schema.dart.excerpt.json') }}

In the above example, the `isAdmin` field will default to `false` if no value is provided.

??? question "`withDefault()`"

    `withDefault()` is similar to `clientDefault()`, but the default value is set in the database.

    {{ load_snippet('db_default','lib/snippets/schema.dart.excerpt.json') }}

    <h4>What's the difference?</h4>

    When a record is created with an empty `isAdmin` field, there are 2 places where the default value could potentially be set:

    1. When using `clientDefault`, the default value will be set in your Dart code. This is similar to setting a default value on a class constructor.

        As far as the database is concerned, the `isAdmin` field is a regular `bool` column. We can add, remove or change the default value without migrating the database.

    2. When using `withDefault`, the default value will be set in the database. This is similar to setting a default value in a SQL database.
        {{ load_snippet('db_default','lib/snippets/schema.dart.excerpt.json') }}

        The `isAdmin` field is now a `BoolColumn` with a default value of `false`. If you change the default value, you will need to migrate the database.
    
    In most cases, you should use `clientDefault`. It's more flexible and doesn't require you to migrate the database when changing the default value. Drift includes `withDefault` for SQL database compatibility, but its practical use cases are limited.

## Unique Columns

To ensure that a column can only contain unique values, use the `unique` method.

{{ load_snippet('unique_columns','lib/snippets/schema.dart.excerpt.json') }}

Now the `name` column will only accept unique values. If you try to insert a record with a duplicate `name`, an exception will be thrown.

### Multi-Column Uniqueness

You can also enforce uniqueness across multiple columns by overriding the `uniqueKeys` getter in your table class.

For example, in a restaurant management app, you might want to ensure that a table is only reserved once at a time. You can enforce this by making the combination of `time` and `table` unique.

{{ load_snippet('unique-table','lib/snippets/schema.dart.excerpt.json') }}

Now if we created a record with the same time and the same table, an exception will be thrown.

### `DateTime`

Drift handles most of the complexity of working with `DateTime` objects for you.  
You can use `DateTime` objects directly in your Dart code, and Drift will take care of converting them to the correct format for the database.

{{ load_snippet('datetime','lib/snippets/schema.dart.excerpt.json') }}

Under the hood, Drift can store `DateTime` objects in one of two ways:

1. As Unix timestamps (integers): This is the default method. It's slightly faster but provides only second-level accuracy and doesn't store timezone information.
2. As ISO-8601 strings (text): This method is recommended for most applications. It's more precise, timezone-aware, and human-readable.

By default, Drift stores `DateTime` objects as Unix timestamps for backward compatibility reasons. However, we recommend using ISO-8601 strings for new projects. To enable this, set the `store_date_time_values_as_text` option in your `build.yaml` file.

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

### Enums

Drift provides support for storing Dart enums in your database. Enums can be stored either as integers (using their index) or as strings (using their name).

{{ load_snippet('enum','lib/snippets/schema.dart.excerpt.json') }}

!!! warning "Enum Caution"
    While enums can be convenient, they come with some risks when used in database schemas:

    1. **Changing Enum Order**: If you use `intEnum`, adding, removing, or reordering enum values can break existing data. The integer stored in the database may no longer correspond to the correct enum value.

    2. **Renaming Enum Values**: If you use `textEnum`, renaming an enum value will make it impossible to read existing data for that value.

### Custom Types

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




## Naming Customization

### Table & Column Name

By default, Drift uses `snake_case` for table and column names in the database. For example, a `TodoItems` table becomes `todo_items`, and an `emailAddress` column becomes `email_address`.

This can be customized by setting the `case_from_dart_to_sql` option in your `build.yaml` file.

```yaml title="build.yaml"
targets:
  $default:
    builders:
      drift_dev:
        options:
          case_from_dart_to_sql : snake_case # default
          # case_from_dart_to_sql : preserve # (Original case)
          # case_from_dart_to_sql : camelCase
          # case_from_dart_to_sql : CONSTANT_CASE
          # case_from_dart_to_sql : PascalCase
          # case_from_dart_to_sql : lowercase
          # case_from_dart_to_sql : UPPERCASE

```

#### Custom Names

If you prefer to use custom names for tables or columns, you can override the default naming behavior:

- To customize the table name, override the `tableName` getter in your table class.
- To customize column names, use the `named()` method when defining the column.

Here's an example demonstrating these techniques:

{{ load_snippet('custom_table_name','lib/snippets/schema.dart.excerpt.json') }}

### Data Class Name

Drift generates a data class for each table:

- Table name ending with "s": Remove the "s" (e.g., `Superheroes` → `Superhero`)
- Other table names: Append "Data" (e.g., `Category` → `CategoryData`)

This name can be customized by using the `@DataClassName` decorator.

{{ load_snippet('bad_name','lib/snippets/schema.dart.excerpt.json') }}

### Json Key

Drift automatically generates `fromJson` and `toJson` methods for each table's data class. These methods handle JSON serialization and deserialization. By default, the JSON keys correspond to the column names, converted to `snake_case`. For example:

- A column named `emailAddress` will use `email_address` as its JSON key.
- A column named `userName` will use `user_name` as its JSON key.

This name can be customized by using the `@JsonKey` decorator.

{{ load_snippet('json_key','lib/snippets/schema.dart.excerpt.json') }}

#### Json Key from Column Name

Drift offers an option to use the column name as the JSON key. When this option is enabled, the column name specified in  `named()` method in Dart will be used directly as the JSON key.

Enable this by setting `use_column_name_as_json_key` in your `build.yaml` file:

```yaml title="build.yaml"
targets:
  $default:
    builders:
      drift_dev:
        options:
          use_sql_column_name_as_json_key: false # (default)
          # To use column name as JSON key
          # use_sql_column_name_as_json_key: true 
```

## Advanced

### Reusable Mixins

There are a few tricks you can use with Drift. You can essentially do anything you would in a simple Dart project with your code.

One common feature is to separate columns into different places and then reuse them. For example, consider the `updated_at`, `created_at`, and `deleted_at` columns. Many tables/models may need these three fields to track and analyze the creation, deletion, and updates of entities in a system.

You can define these columns once and then reuse them.

{{ load_snippet('table_mixin','lib/snippets/schema.dart.excerpt.json') }}

### Custom Constraints

Drift supports adding custom SQL constraints to your tables and columns. 

To add a custom constraint to a column, use the `customConstraint` method.

{{ load_snippet('custom_column_constraint','lib/snippets/schema.dart.excerpt.json') }}

Keep in mind that a `customConstraint` will override the default `NOT NULL` constraint. So if you want to keep the `NOT NULL` constraint, you need to add it manually.

{{ load_snippet('custom_column_constraint_not_nullable','lib/snippets/schema.dart.excerpt.json') }}

You can also add custom constraints to the table itself by overriding the `tableConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/schema.dart.excerpt.json') }}

!!! note "SQL Validation"

    Don't worry about syntax errors or unsupported features. Drift will validate the SQL you provide. If there are any issues, drift will throw an error during code generation.

### Custom Checks

Drift supports using expressions to check the validity of data in a column. See the [expression](./dart_api/expressions.md) documentation for more information.
Here is a small example showing how to use a custom check to enforce that the `age` column is greater than 0.

{{ load_snippet('custom-check','lib/snippets/schema.dart.excerpt.json') }}

If any record is inserted with an `age` less than 0, an exception will be thrown.

Keep in mind that this check is run in the database, so if you change this check you will need to migrate the database.

### `BigInt` Columns

Use the standard `int` type for storing integers as it is efficient for typical values. Only use `BigInt` for extremely large numbers when compiling to JavaScript, as it ensures accuracy but has a performance cost. For more details, refer to the dart-lang [documentation](https://dart.dev/guides/language/numbers#what-should-you-do).

