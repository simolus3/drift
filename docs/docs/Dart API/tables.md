---

title: Tables
description: Everything there is to know about defining SQL tables in Dart.

---

SQL tables are the foundation of any relational database.   
Use them to define the structure of the data
you want to store.

Define a table by creating a class that extends `Table`.  

{{ load_snippet('table','lib/snippets/setup/database.dart.excerpt.json') }}

!!! note "Naming conventions"
    
    Table names should be in plural form, like `Users` or `Categories`.  
    This will ensure that the generated data classes are named correctly.

A dataclass is generated for each table, which can be used to interact with the database.
See the [Dataclass](./dataclass.md) page for more information.

## Columns

Columns are defined by getters in the table class.

For instance, in the example above, `#!dart IntColumn get category => integer().nullable()();` defined a column named `category` that can store integers and is nullable.

### Supported Types

Drift supports a variety of column types out of the box.  
Additional types can be stored using [type converters](../type_converters.md).

| Dart type   | Column       | Corresponding SQLite type                                                                      |
| ----------- | ------------ | ---------------------------------------------------------------------------------------------- |
| `int`       | `integer()`  | `INTEGER`                                                                                      |
| `BigInt`    | `int64()`    | `INTEGER` (useful for large values on the web)                                                 |
| `double`    | `real()`     | `REAL`                                                                                         |
| `boolean`   | `boolean()`  | `INTEGER`, which a `CHECK` to only allow `0` or `1`                                            |
| `String`    | `text()`     | `TEXT`                                                                                         |
| `DateTime`  | `dateTime()` | `INTEGER` (default) or `TEXT` depending on [options](#datetime-options)                        |
| `Uint8List` | `blob()`     | `BLOB`                                                                                         |
| `Enum`      | `intEnum()`  | `INTEGER` (more information available [here](../type_converters.md#implicit-enum-converters)). |
| `Enum`      | `textEnum()` | `TEXT` (more information available [here]("../type_converters.md#implicit-enum-converters")).  |

!!! note "JSON Serialization"
    
    The way drift maps Dart types to SQL types is independent of how it serializes data to JSON.  
    For example, Dart `bool` values are stored as `0` or `1` in the database, but as `true` or `false` in JSON.

### Optional Columns

Drift adopts Dart's non-nullable by default approach.    
If you do want to make a column nullable, use `nullable()`:

{{ load_snippet('nnbd','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Columns in Dart-defined tables default to `NOT NULL` in SQL. Omitting values during insertion causes exceptions.

### Default Values


Default values can be set for columns using two methods:

1. **`withDefault`**: For constant values
```dart
class Preferences extends Table {
    TextColumn get name => text()();
    BoolColumn get enabled => boolean().withDefault(const Constant(false))();
}
```

2. **`clientDefault`**: For dynamic values
```dart
class Users extends Table {
    TextColumn get id => text().clientDefault(() => Uuid().v4())();
}
```

**Key points**:

- `withDefault` will store the default value in the database, while `clientDefault` will generate the default value on the client side.

- For constant values, like `false`, `true`, or `0`, `withDefault` is more efficient.
`clientDefault` is more flexible for dynamic values like `DateTime.now()` or `Uuid().v4()`.

- Changing the default value for a column with `withDefault` requires a schema migration, while `clientDefault` allows you to change the default value without a schema migration.

### Checks (Data Validation)

Use the `check` method to enforce specific conditions. This method takes a Boolean expression as an argument and is evaluated for each insert or update.

For example, the following code ensures that the `age` column is always greater than `0`:

{{ load_snippet('check','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The `check` method generates a `CHECK` constraint in the SQL table definition, which validates the column for each data modification.

To add, remove, or modify a check constraint after table creation, you must write a [schema migration](../Migrations/index.md).

See the [Expressions](../Expressions/index.md) page for more on writing expressions.

!!! info "Thrown Exceptions"

    Validation/Checks are enforced at the database level.  
    Creating a `User` dataclass with an `age` of `-1` will not throw an exception in Dart.

!!! note "Recusive Checks"

    The dart analyzer may report a [`recursive_getters`](https://dart.dev/tools/linter-rules/recursive_getters) error when using a column in a check expression.  
    This can be safely ignored, as this code is never executed.


### Unique Columns

#### Single Column

Use the `unique()` method to enforce that a column must contain unique values.
For example, the following code ensures that each users `username` is unique:

{{ load_snippet('unique-column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

#### Multiple Columns

If you want to enforce a combination of columns to be unique, override the `uniqueKeys` getter in your table class:
For example, if one wanted to ensure that an author can't write two books with the same title:

{{ load_snippet('unique-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Custom Types

Any Dart object can be stored if a [Type Converter](../type_converters.md) is provided.

{{ load_snippet('table','lib/snippets/type_converters/converters.dart.excerpt.json') }}

For more information, see the [Type Converters](../type_converters.md) page.

### `BigInt`


Use `int64()` to store large integers in Dart.
This will preserve precision in JavaScript-compiled apps. 

!!! note annotate "When to use `int64()`"

 The standard `integer()` column suffices for most cases, especially non-web apps.   
 Only use `int64()` for web apps with values exceeding 2^52. (1)

1.  This is a huge number, so you're unlikely to reach this limit in practice. 4,503,599,627,370,496 to be exact.
So unless you're dealing with numbers that large, you can stick with `integer()`.


##### Migration to/from `BigInt`

Drift stores `int` and `BigInt` values in the same column type in sqlite3, so you can switch between the two without a schema migration.  

##### Supported Backends

`BigInt` is not supported by `drift_sqflite`.


##### Expressions

When using `BigInt` columns in expressions, you can use `dartCast()` to ensure the correct type is returned.

For example, `(table.columnA * table.columnB).dartCast<BigInt>()` will return a `BigInt` value, even if `columnA` and `columnB` are defined as regular integers.


### `DateTime`

Drift supports two approaches to storing `DateTime`:

<div class="annotate" markdown>

1. **UNIX Timestamp** [Default]:  

    DateTime values are stored in seconds as an SQL `INTEGER` containing the Unix timestamp (e.g. `1722169674`). This default behavior can be changed by setting the `store_date_time_values_as_text` [build option](../Generation options/index.md).  
    
    <!-- | -->
**Pros**
    
    * **Performance**: Intergers are more efficient to store and compare than textual representations.  
    
    **Cons**:  

    * **No Timezones**: All local time information is lost. (1)  
    
    * **Less Precision**: Only stored as seconds, so milliseconds are truncated.


2. __ISO-8601 String__:   

    Datetime values are stored as a formatted text based on `DateTime.toIso8601String()`.  
    UTC values are stored unchanged (e.g. `2022-07-25 09:28:42.015Z`), while local values have their
    UTC offset appended (e.g. `2022-07-25T11:28:42.015 +02:00`).  

    **Pros**  
    
    * **Timezones Aware**: Local time information is preserved.  

    * **Precise**: Milliseconds are stored.  
    
    **Cons**:  

    * **Performance**: Textual values are less efficient to store and compare than integers.  
    

    ??? info "Timezone Handling"

        Most of sqlite3's date and time functions operate on UTC values, but parsing
        date-times in SQL respects the UTC offset added to the value.  
        When reading values back from the database, drift will use `DateTime.parse`
        as following:  

        - If the textual value ends with `Z`, drift will use `DateTime.parse`
              directly. The `Z` suffix will be recognized and returned with a UTC value. 
        - If the textual value ends with a UTC offset (e.g., `+02:00`), drift first
              uses `DateTime.parse`, which respects the modifier but returns a UTC
              datetime. Drift then calls `toLocal()` on this intermediate result to
              return a local value.
        - If the textual value neither has a `Z` suffix nor a UTC offset, drift
              will parse it as if it had a `Z` modifier, returning a UTC datetime.
              The motivation for this is that the `datetime` function in sqlite3 returns
              values in this format and uses UTC by default.  

        This behavior works well with the date functions in sqlite3 while also
        preserving "UTC-ness" for stored values.

</div>

1. If you would like to store `DateTime` objects that know their time zones, you should use Option 2.

Drift stores `DateTime` values as unix timestamps by default. This can be changed by setting the `store_date_time_values_as_text` [build option](../Generation options/index.md).

Migrating between the two modes is possible but requires a [manual migration](#migrating-between-the-two-modes).


## Custom Constraints

Some column and table constraints aren't supported through Drift API. This includes the collation
of columns, which you can apply using `customConstraint`:

```dart
class Groups extends Table {
    TextColumn get name => integer().customConstraint('COLLATE BINARY')();
}
```

Applying a `customConstraint` will override all other constraints that would be included by default. 
In particular, we must also include the `NOT NULL` constraint again.

You can also add table-wide constraints by overriding the `customConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}



## Primary Keys

If your table has an `IntColumn` with an `autoIncrement()` constraint, drift recognizes that as the default
primary key.

To use a custom primary key, override the `primaryKey` getter in your table.
Here is an example using a UUID as the primary key:

{{ load_snippet('primary-key','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Multiple columns can be used as a composite primary key by returning a set of columns.

!!! note "Primary Key Syntax"

    The primary key must essentially be constant so that the generator can recognize it. That means:

    - it must be defined with the `=>` syntax, function bodies aren't supported
    - it must return a set literal without collection elements like `if`, `for` or spread operators

## References

[Foreign Keys](https://www.sqlite.org/foreignkeys.html) are used to create relationships between tables.
Use the `references` method to define a foreign key constraint.

{{ load_snippet('references','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The first parameter to `references` is the table to reference.
The second parameter is a [symbol](https://dart.dev/guides/language/language-tour#symbols) of the column to use for the reference.




!!! info "Foreign Key Constraints"

    Be aware that, in sqlite3, foreign key references aren't enabled by default.
    They need to be enabled with `PRAGMA foreign_keys = ON`.
    A suitable place to issue that pragma with drift is in a [post-migration callback](../Migrations/index.md#post-migration-callbacks).

Optionally, the `onUpdate` and `onDelete` parameters can be used to describe what
should happen when the target row gets updated or deleted.

By default, `NO ACTION` is used for both. This mean that if foreign key constraints are enabled, an update or delete of the target row will fail if it would violate the foreign key constraint.

!!! example "Example"

    We have a `users` table with a `group_id` column that references the `groups` table.
    The admin group has an id of `1`. Each user in the admin group has a `group_id` of `1`.

    If we were to delete the admin group, or change its id, the `onUpdate` and `onDelete` parameters would determine what happens.
    
    By default, the operation would fail. However we could change the `onDelete` parameter to `cascade` to delete all users in the admin group when the group is deleted. Or we could set it to `setNull` to set the `group_id` of all users in the admin group to `null` when the group is deleted.

    See the [sqlite documentation](https://sqlite.org/foreignkeys.html#fk_actions) for more information on the available actions.

## Table Name

By default, drift uses the `snake_case` name of the Dart getter in the database. For instance, the
table

{{ load_snippet('(full)','lib/snippets/dart_api/old_name.dart.excerpt.json') }}

Would be generated as `#!sql CREATE TABLE enabled_categories (parent_category INTEGER NOT NULL)`.

To override the table name, simply override the `tableName` getter. An explicit name for
columns can be provided with the `named` method:

{{ load_snippet('names','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The updated class would be generated as `#!sql CREATE TABLE categories (parent INTEGER NOT NULL)`.

## Indexes

[SQL Indexes](https://sqlite.org/lang_createindex.html) are like book indexes: they help find information quickly. Without them, you'd have to scan the whole database for each search, which is slow. Indexes make searches much faster, but slightly slow down adding new data.

!!! tip "When to use indexes"

    Any column that is filtered or sorted on frequently should have an index.  
    Fields likes `age`, `name`, `email`, `created_at`, `updated_at`, etc. are good candidates for indexing.

Use the `@TableIndex` annotation to define an index on a table.  
Each index needs to have its own unique name. Typically, the name of the table is part of the
index' name to ensure unique names.  
These can be used multiple times to define multiple indexes on a table.


{{ load_snippet('index','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Primary keys are automatically indexed, so you don't need to add an index for them.

!!! note "Multi-Column indexes"

    While these two syntaxes look very similar, they have different meanings:

    1. **Multiple Indexes on a Table**

        {{ load_snippet('mulit-single-col-index','lib/snippets/dart_api/tables.dart.excerpt.json', indent=8) }}
        This creates two separate indexes, one for each column. 
        Queries that filter on each column independently can use the index.
        However, queries that filter on both columns can't use the index.

    2. **Multi-Column Index**

        {{ load_snippet('multi-col-index','lib/snippets/dart_api/tables.dart.excerpt.json', indent=8) }}

        This creates a single index that covers both columns. Queries that use both or the first column (name) can use the index. However, queries that only filter on the second column (age) can't use the index.

    This topic is quite complex, and out of scope for this documentation. See [here](https://www.sqlitetutorial.net/sqlite-index/) for more information.

