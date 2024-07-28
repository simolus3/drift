---

title: Columns
description: Everything there is to know about defining SQL columns in drift.

---

Define columns by declaring a getter starting with the type of the column,
its name in Dart, and the definition mapped to SQL.    

In the example below, `#!dart IntColumn get category => integer().nullable()();` defines a column
holding nullable integer values named `category`.

{{ load_snippet('table','lib/snippets/setup/database.dart.excerpt.json') }}

## Column Types

Drift supports a variety of column types out of the box.  
Other types can be stored using [type converters](../type_converters.md).

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

## Nullable

Drift adopts Dart's non-nullable by default approach.    
If you do want to make a column nullable, just use `nullable()`:

{{ load_snippet('nnbd','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Columns in Dart-defined tables default to `NOT NULL` in SQL. Omitting values during insertion causes exceptions. Drift provides compile-time warnings for this when using SQL too.

## Defaults


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
For dynamic values, like `DateTime.now()` or `Uuid().v4()`, `clientDefault` is more flexible.

- Changing the default value for a column with `withDefault` requires a schema migration, while `clientDefault` allows you to change the default value without a schema migration.

## Checks (Data Validation)

Use the `check` method to enforce specific conditions. This method takes a Boolean expression as an argument, which is evaluated for each insert or update.

For example, the following code ensures that the `age` column is always greater than `0`:

{{ load_snippet('check','lib/snippets/dart_api/tables.dart.excerpt.json') }}

This generates a `CHECK` constraint in the SQL table definition, which validates the column for each data modification.

You must write a [schema migration](../Migrations/index.md). to add, remove, or modify a check constraint after table creation.

For more on writing expressions, see the [Expressions](../Expressions/index.md) page.

!!! info "Thrown Exceptions"

    Validation/Checks are only enforced at the database level.  
    Creating a `User` dataclass with an `age` of `-1` will not throw an exception in Dart.

!!! note "Recusive Checks"

    The dart analyzer may report a [`recursive_getters`](https://dart.dev/tools/linter-rules/recursive_getters) error when using a column in a check expression.  
    This can be safely ignored, as this code is never executed.


## Unique Columns

### Single Column

Use the `unique()` method to enforce that a column must contain unique values.
For example, the following code ensures that each users `username` is unique:

{{ load_snippet('unique-column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Multiple Columns

If you want to enforce a combination of columns to be unique, override the `uniqueKeys` getter in your table class:
For example, if wanted to ensure that an author can't write 2 books with the same title:

{{ load_snippet('unique-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

## Custom Types

Any Dart object can be stored if a [Type Converter](../type_converters.md) is provided.

{{ load_snippet('table','lib/snippets/type_converters/converters.dart.excerpt.json') }}

See the [Type Converters](../type_converters.md) page for more information.

## `BigInt`


Use `int64()` to store large integers in Dart.
This will preserve precision in JavaScript-compiled apps. 

!!! note annotate  "When to use `int64()`"

    For most cases, especially non-web apps, the standard `integer()` column suffices.   
    Only use `int64()` for web apps dealing with values exceeding 2^52. (1)

1.  This is an absolutly huge number, so you're unlikely to run into this limit in practice. 4,503,599,627,370,496 to be exact.
So unless you're dealing with numbers that large, you can stick with `integer()`.


##### Migration to/from `BigInt`

Drift stores `int` and `BigInt` values in the same column type in sqlite3, so you can switch between the two without a schema migration.  

##### Supported Backends

`BigInt` is not supported by `drift_sqflite`.


##### Expressions

When using `BigInt` columns in expressions, you can use `dartCast()` to ensure the correct type is returned.

For example, `(table.columnA * table.columnB).dartCast<BigInt>()` will return a `BigInt` value, even if `columnA` and `columnB` are defined as regular integers.


## `DateTime`

Drift supports two approaches of storing `DateTime`:

<div class="annotate" markdown>

1. **UNIX Timestamp** [Default]:  

    DateTime values are stored as an SQL `INTEGER` containing the unix timestamp in seconds. (e.g. `1722169674`)
    This is the default behavior and can be changed by setting the `store_date_time_values_as_text` [build option](../Generation options/index.md).

    **Pros**
    
    * **Performance**: Intergers are more efficient to store and compare than textual representations.  
    
    **Cons**:  

    * **No Timezones**: All local time information is lost. (1)  
    
    * **Less Precision**: Only stored as seconds, so milliseconds are truncated.
    
3. __ISO-8601 String__:   

    Datetime values are stored as formated text based on `DateTime.toIso8601String()`.  
    UTC values are stored unchanged (e.g. `2022-07-25 09:28:42.015Z`), while local values have their
    UTC offset appended (e.g. `2022-07-25T11:28:42.015 +02:00`).  

    **Pros**
    
    * **Timezones Aware**: Local time information is preserved.
    * **Precise**: Milliseconds are stored.
    
    **Cons**:  

    * **Performance**: Textual values are less efficient to store and compare than integers.
    

    ??? info "Timezone Handling"

        Most of sqlite3's date and time functions operate on UTC values, but parsing
        datetimes in SQL respects the UTC offset added to the value.  
        When reading values back from the database, drift will use `DateTime.parse`
        as following:  

        - If the textual value ends with `Z`, drift will use `DateTime.parse`
              directly. The `Z` suffix will be recognized and a UTC value is returned.  
        - If the textual value ends with a UTC offset (e.g. `+02:00`), drift first
              uses `DateTime.parse` which respects the modifier but returns a UTC
              datetime. Drift then calls `toLocal()` on this intermediate result to
              return a local value.
        - If the textual value neither has a `Z` suffix nor a UTC offset, drift
              will parse it as if it had a `Z` modifier, returning a UTC datetime.
              The motivation for this is that the `datetime` function in sqlite3 returns
              values in this format and uses UTC by default.  

        This behavior works well with the date functions in sqlite3 while also
        preserving "UTC-ness" for stored values.

</div>

1. If you would like to store `DateTime` objects which are aware of their timezone, you should use Option 2.

Drift stores `DateTime` values as unix timestamps be default. This can be changed by setting the `store_date_time_values_as_text` [build option](../Generation options/index.md).

Migrating between the two modes is possible, but requires a [manual migration](#migrating-between-the-two-modes).


## Custom Constraints

Some column and table constraints aren't supported through Drift API. This includes the collation
of columns, which you can apply using `customConstraint`:

```dart
class Groups extends Table {
  TextColumn get name => integer().customConstraint('COLLATE BINARY')();
}
```

Applying a `customConstraint` will override all other constraints that would be included by default. 
In particular, that means that we need to also include the `NOT NULL` constraint again.

You can also add table-wide constraints by overriding the `customConstraints` getter in your table class.

{{ load_snippet('custom-constraint-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}
