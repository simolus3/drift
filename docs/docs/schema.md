---

title: Schema
description: Define the schema of your database.

---

<h1>Schema Definition</h1>

## Overview

You can define your schema using Dart or SQL(1). Use whichever method you're most comfortable with.  
{ .annotate }

1. The SQL is type-checked at compile time and the generated code is also type-safe.
    You aren't sacrificing type safety or performance if you choose to use SQL.

This page focuses on Dart. For the SQL approach, see the [SQL Schema](./sql_schema.md) documentation.

#### Basic Example

{{ load_snippet('superhero_schema_with_db','lib/snippets/schema.dart.excerpt.json',title="schema.dart") }}

This example defines a `Superheros` table with columns for id, name, secret name, age, and height. The `AppDatabase` class ties it all together, creating a database with the `Superheros` table.

Once, code generation is complete, you can interact with the database using the `AppDatabase` class:

{{ load_snippet('superhero_query','lib/snippets/schema.dart.excerpt.json') }}

In the following sections, we'll dive deeper into the various aspects of schema definition using Drift.

---

## Tables

In Drift, a table is represented by any class which extends the `Table` class.  


```dart
class Superheros extends Table {
  // Columns go here
}

class Categories extends Table {
  // Columns go here
}
```

!!! tip "Table Naming"
    Table classes should be named in plural form (e.g., `Superheros`, `Categories`). This convention generally leads to more appropriately named generated classes. For more information, see the [Naming](#naming) section.
 

## Columns

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

## Required

By default, all columns are required. To make a column optional, use the `nullable()` method.

Example:

{{ load_snippet('optional_columns','lib/snippets/schema.dart.excerpt.json') }}

Now the `age` column is optional. If you try to insert a record without an `age`, it will be set to `null`.

## Defaults

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

## Primary Keys

Every table in a relational database needs a primary key - a column (or set of columns) that uniquely identifies each row.

This is the recommended way to define a primary key for a table:

```dart
class Superheros extends Table {
  late final id = integer().autoIncrement()();
  // other columns...
}
```

When you use define a single `integer().autoIncrement()()` column on a table, Drift automatically sets this column as the primary key. You don't need to do anything else.

!!! tip "Reusable Mixin"
    In fact, the above column definition is so common that Drift provides a mixin to make it easier. You can use the `PrimaryKey` 

    {{ load_snippet('base_pk_class','lib/snippets/schema.dart.excerpt.json') }}

### Custom Primary Keys

If you want to use a different column (or set of columns) as the primary key, you can override the `primaryKey` getter in your table class:

{{ load_snippet('custom_pk','lib/snippets/schema.dart.excerpt.json') }}

In this example, the `email` column is set as the primary key.



## Unique Columns

To ensure that a column can only contain unique values, use the `unique` method.

{{ load_snippet('unique_columns','lib/snippets/schema.dart.excerpt.json') }}

Now the `name` column will only accept unique values. If you try to insert a record with a duplicate `name`, an exception will be thrown.

### Multi-Column Uniqueness

You can also enforce uniqueness across multiple columns by overriding the `uniqueKeys` getter in your table class.

For example, in a restaurant management app, you might want to ensure that a table is only reserved once at a time. You can enforce this by making the combination of `time` and `table` unique.

{{ load_snippet('unique-table','lib/snippets/schema.dart.excerpt.json') }}

Now if we created a record with the same time and the same table, an exception will be thrown.


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



## Enums

Drift provides support for storing Dart enums in your database. Enums can be stored either as integers (using their index) or as strings (using their name).

{{ load_snippet('enum','lib/snippets/schema.dart.excerpt.json') }}

!!! warning "Enum Caution"
    While enums can be convenient, they come with some risks when used in database schemas:

    1. **Changing Enum Order**: If you use `intEnum`, adding, removing, or reordering enum values can break existing data. The integer stored in the database may no longer correspond to the correct enum value.

    2. **Renaming Enum Values**: If you use `textEnum`, renaming an enum value will make it impossible to read existing data for that value.

    3. **Adding New Values**: Adding new enum values (especially in the middle of the enum) can cause issues with existing data or queries that assume a certain set of values.







## `DateTime` Columns

Drift handles most of the complexity of working with `DateTime` objects for you.  
You can use `DateTime` objects directly in your Dart code, and Drift will take care of converting them to the correct format for the database.

{{ load_snippet('datetime','lib/snippets/schema.dart.excerpt.json') }}

Under the hood, Drift can store `DateTime` objects in one of two ways:

1. As Unix timestamps (integers): This is the default method. It's slightly faster but provides only second-level accuracy and doesn't store timezone information.
2. As ISO-8601 strings (text): This method is recommended for most applications. It's more precise, timezone-aware, and human-readable.

By default, Drift stores `DateTime` objects as Unix timestamps for backward compatibility reasons. However, we recommend using ISO-8601 strings for new projects. To enable this, set the `store_date_time_values_as_text` option in your `build.yaml` file.

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          store_date_time_values_as_text: false # (default)
          # To use ISO 8601 strings
          # store_date_time_values_as_text: true
```

## Naming

Drift generates quite a bit of SQL and Dart code for you. This section will help you customize the names of tables and columns in the database.

### Data Class Name

Drift generates a data class for each record in the database. The name of this class is derived from the table name. 

- If the table name ends with an "s", the "s" is removed. For example, a table named `Superheroes` will have a data class named `Superhero`.
- If the table name doesn't end with an "s", the name is used with `Data` appended to it. For example, a table named `Category` will have a data class named `CategoryData`.

If you want to customize the name of the data class, use the `@DataClassName` decorator.

{{ load_snippet('bad_name','lib/snippets/schema.dart.excerpt.json') }}

### Json Key

Drift generates a `toJson()` method for each data class. By default, the keys in the JSON map will be the `snake_case` version of the column getter names.

If you want to customize the key in the JSON map, use the `@JsonKey` decorator.

{{ load_snippet('json_key','lib/snippets/schema.dart.excerpt.json') }}

Drift also has an option to use the column name as the key in the JSON map. To enable this, set the `use_column_name_as_json_key` option in your `build.yaml` file.

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          use_sql_column_name_as_json_key: false # (default)
          # To use column name as JSON key
          # use_sql_column_name_as_json_key: true 
```

### Table Name

!!! note "Raw SQL"

    If you don't plan on writing raw SQL queries, you can skip this section.

Drift will use the name of your table in `snake_case` when interacting with the database. For instance, the table `TodoItems` will be stored in the database as `todo_items`. 

To customize the name of the table in SQL, override the `tableName` getter in your table class.

{{ load_snippet('custom_table_name','lib/snippets/schema.dart.excerpt.json') }}

You can also change what "case" is used by settings a generator option in your `build.yaml` file.

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          case_from_dart_to_sql : snake_case # (default)
        # You can also use other cases
        # case_from_dart_to_sql : preserve # (Original case)
        # case_from_dart_to_sql : camelCase
        # case_from_dart_to_sql : CONSTANT_CASE
        # case_from_dart_to_sql : PascalCase
        # case_from_dart_to_sql : lowercase
        # case_from_dart_to_sql : UPPERCASE

```

### Column Name

!!! note "Raw SQL"

    If you don't plan on writing raw SQL queries, you can skip this section.

By default, Drift will use the name of the Dart getter as the column name in SQL. For instance, the column `createdAt` will be stored in the database as `created_at`. 

If you want to customize the column name in SQL, use the `.named()` method.

{{ load_snippet('named_column','lib/snippets/schema.dart.excerpt.json') }}


## Advanced

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
