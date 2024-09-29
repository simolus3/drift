---

title: Schema
description: Define the schema of your database.

---

## Overview

In Drift, your schema is represented as a table. Each column in the table represents a field in your data class.

Take this example of a table that stores superheroes:

| ID  | Name      | Secret Name  | Age    | Height |
| --- | --------- | ------------ | ------ | ------ |
| 1   | Superman  | Clark Kent   | 35     | 6'2"   |
| 2   | Batman    | Bruce Wayne  | 40     | 6'0"   |
| 3   | Spiderman | Peter Parker | 25     | 5'10"  |
| 4   | Ironman   | Tony Stark   | `null` | 6'1"   |
| 5   | Thor      | `null`       | 1500   | `null` |


Here we have a table with 5 columns: `ID`, `Name`, `Secret Name`, `Age`, and `Height`. Each row in the table represents a single superhero.

Also, we need to limit how the data is stored, for instance:

- `ID` and `Name` should be unique for each row.
- `Secret Name`, `Age`, and `Height` are optional fields.

You can easily define a table in Drift using the following syntax:

{{ load_snippet('superhero_schema','lib/snippets/schema.dart.excerpt.json') }}

After defining the schema, add the table to the database. 

{{ load_snippet('superhero_database','lib/snippets/schema.dart.excerpt.json') }}


Now, run the code generator:
```bash
dart run build_runner build
```

<h4>Congratulations! 🎉🎉</h4>

You've successfully defined the schema for your database.
You can now use the generated code to interact with your database.

{{ load_snippet('superhero_query','lib/snippets/schema.dart.excerpt.json') }}


It's all pretty simple, right? 🚀  

---

## Built-in Types

Drift supports the following column types:

| Dart Type          | Drift Column        |
| ------------------ | ------------------- |
| `#!dart  int`      | `#!dart integer()`  |
| `#!dart  BigInt`   | `#!dart int64()`    |
| `#!dart  String`   | `#!dart  text()`    |
| `#!dart  bool`     | `#!dart boolean()`  |
| `#!dart  double`   | `#!dart real()`     |
| `#!dart Uint8List` | `#!dart blob()`     |
| `#!dart DateTime`  | `#!dart dateTime()` |

Other types can be stored in the database by converting them to one of the above types. See [Custom Types](#custom-types) for more information.


## Optional Columns

By default, all columns are required. If you want a column to be nullable use the `nullable()` method. This will make the column optional and allow it to be set to `null`.

{{ load_snippet('optional_columns','lib/snippets/schema.dart.excerpt.json') }}

Now the `age` column is optional and can be set to `null`.

{{ load_snippet('optional_usage','lib/snippets/schema.dart.excerpt.json') }}


## Default Values

To set default values for your database fields, use the `clientDefault` method.

{{ load_snippet('client_default','lib/snippets/schema.dart.excerpt.json') }}

In this example, `isAdmin` field will default to `false` if not set.

??? question "What's `withDefault()`"

    `withDefault()` is similar to `clientDefault()`, but the default value is set in the database.

    {{ load_snippet('db_default','lib/snippets/schema.dart.excerpt.json') }}

    <h4>What's the difference?</h4>

    When a record is created with an empty `isAdmin` field, there are 2 places where the default value could potentially be set:

    1. When using `clientDefault`, the default value will be set in your Dart code. This is similar to setting a default value on a class constructor.
        {{ load_snippet('dart_default','lib/snippets/schema.dart.excerpt.json') }}

        As far as the database is concerned, the `isAdmin` field is a regular `bool` column. We can add, remove or change the default value without migrating the database.

    2. When using `withDefault`, the default value will be set in the database. This is similar to setting a default value in a SQL database.
        {{ load_snippet('db_default','lib/snippets/schema.dart.excerpt.json') }}

        The `isAdmin` field is now a `BoolColumn` with a default value of `false`. If you change the default value, you will need to migrate the database.
    
    In most cases, you should use `clientDefault`. It's more flexible and doesn't require you to migrate the database when changing the default value. Drift includes `withDefault` for SQL database compatibility, but its practical use cases are limited.

## Unique Columns

To ensure that a column only contains unique values, use the `unique` method.

{{ load_snippet('unique_columns','lib/snippets/schema.dart.excerpt.json') }}

Now the `name` column will only accept unique values. If you try to insert a record with a duplicate `name`, an exception will be thrown.

### Multi-Column Uniqueness

You can also enforce uniqueness across multiple columns by overriding the `uniqueKeys` getter in your table class.

For example, he we want to ensure that we don't reserve the same table for the same time.

{{ load_snippet('unique-table','lib/snippets/schema.dart.excerpt.json') }}

Now if we created a record with the same time and the same table, an exception will be thrown.

## Primary Keys

Every schema needs to have a column which will act as the unique ID. This is called a primary key.

For most use cases, you should use an `int` column with the `autoIncrement` property.

{{ load_snippet('pk','lib/snippets/schema.dart.excerpt.json') }}

Drift is smart enough to know that this should be the primary key for the table. It does this by looking for a single integer column that auto-increments and uses that as the primary key.

!!! tip "Reusable Mixins"
    Writing the same code for every table can be tedious. You can create a mixin that contains the primary key and use it in every table.

    {{ load_snippet('base_pk_class','lib/snippets/schema.dart.excerpt.json') }}

??? question "What's `autoIncrement`?"
    Every item in the database needs a unique ID. But how do you generate this ID? Maybe you could use a random number, but what if you generate the same number twice?

    The simplest solution is to use a `autoIncrement` column. That way, every time you add a new row you get a new ID. The 1st row gets ID 1, the 2nd row gets ID 2, and so on.

### Custom Primary Keys

But what if you want to use a different column as the primary key? You can do that too!  
By overriding the `primaryKey` getter in your table class you can specify which columns should be part of the primary key.

{{ load_snippet('custom_pk','lib/snippets/schema.dart.excerpt.json') }}

In the above example, we're using a `Text` column as the primary key.  

### Composite Keys

There are instances where each row in a table may not any unique ID. However, a combination of columns can be used to uniquely identify a row. This is called a composite primary key.

Multiple columns can be used as a primary key by overriding the `primaryKey` getter in your table class.

??? example "Composite Primary Key"

    Take this example of a table that stores the students in a school:

    | First Name | Last Name | Parent Phone |
    | ---------- | --------- | ------------ |
    | John       | Doe       | 123-456-7890 |
    | Jane       | Doe       | 123-456-7890 |
    | Bob        | Hope      | 987-654-3210 |

    There are no columns that can be used as a unique ID by themselves. However, a combination of `First Name` and `Parent Phone` can be used to uniquely identify a row. (1)
    { .annotate }

    1.  I sure hope there aren't any parents who give the same name to 2 of their kids. 😅

    {{ load_snippet('composite_pk','lib/snippets/schema.dart.excerpt.json') }}


## Custom Types

Any type which can be converted to any of the above types can be used as a column type.

For example, if we wanted to store the built-in `Duration` type, we could convert it to an `int` before storing it. We'll create a custom converter for this.

<div class="annotate" markdown>

{{ load_snippet('converter','lib/snippets/schema.dart.excerpt.json') }}

</div>

1. The 1st type parameter is the Dart type you want to store.
2. The 2nd type parameter is what type you are converting it to.  
    In this case, we are converting `Duration` to `int`.

Then use the `.map()` method to add the converter to the column.

{{ load_snippet('apply_converter','lib/snippets/schema.dart.excerpt.json') }}


Now we can use the `Duration` type as if it were a built-in type.

{{ load_snippet('use_converter','lib/snippets/schema.dart.excerpt.json') }}



## Enums

Dart enums can either be stored as an `int` using their index or as a `String` using their name.

{{ load_snippet('enum','lib/snippets/schema.dart.excerpt.json') }}

!!! warning "Footgun Alert"
    It can be quite easy to break your database by using enums.  
    If you were to change the order of the enum values (if using an `intEnum`) or rename an enum member (when using `textEnum`) you would break your database.




## `int` & `BigInt` Columns

For most cases, use the standard `int` type for storing numbers. It's efficient and works well for typical integer values.

Only use `BigInt` if you need to store extremely large numbers and you will be compiling your app to JavaScript. `BigInt` ensures accurate representation of these large numbers in JavaScript environments, but comes with a slight performance overhead.

For the majority of applications, stick with `int` unless you have a specific need for `BigInt`.



## `DateTime` Columns

Drift handles most of the complexity of working with `DateTime` objects for you.  
When defining `DateTime` columns, use the `dateTime()` method.


{{ load_snippet('datetime','lib/snippets/schema.dart.excerpt.json') }}

Under the hood, however, Drift can store `DateTime` objects in one of two ways:

1. As Unix timestamps (integers): This is the default method. It's slightly faster but provides only second-level accuracy and doesn't store timezone information.
2. As ISO-8601 strings (text): This method is recommended for most applications. It's more precise, timezone-aware, and human-readable.

By default, Drift stores `DateTime` objects as Unix timestamps for backward compatibility. However, we recommend using ISO-8601 strings for new projects. To enable this, set the `store_date_time_values_as_text` option in your `build.yaml` file.

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

## Advanced

### Custom Constraints

Drift supports adding custom SQL constraints to your tables and columns. 

To add a custom constraint to a column, use the `customConstraint` method.

{{ load_snippet('custom_column_constraint','lib/snippets/schema.dart.excerpt.json') }}

Keep in mind that a `customConstraint` will override the default `NOT NULL` constraint. So if you want to keep the `NOT NULL` constraint, you need to add it manually.

{{ load_snippet('custom_column_constraint_not_nullable','lib/snippets/schema.dart.excerpt.json') }}

You can also add custom constraints to the table itself by overriding the `tableConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/schema.dart.excerpt.json') }}

### Custom Checks

Drift supports using expressions to check the validity of data in a column. See the [expression] documentation for more information.
Here is a small example showing how to use a custom check to enforce that the `age` column is greater than 0.

{{ load_snippet('custom-check','lib/snippets/schema.dart.excerpt.json') }}

If any record is inserted with an `age` less than 0, an exception will be thrown.

Keep in mind that this check is run in the database, so if you change this check you will need to migrate the database.