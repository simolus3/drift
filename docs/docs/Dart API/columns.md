---

title: Columns
description: Everything there is to know about defining SQL columns in drift.

---

Columns are defined by getters in the table class.

{{ load_snippet('table','lib/snippets/setup/database.dart.excerpt.json') }}

For instance, in the example above, `#!dart IntColumn get category => integer().nullable()();` defined a column named `category` that can store `#!dart int?`.

### Supported Types

Drift supports a variety of column types out of the box.  
Additional types can be stored using [type converters](../type_converters.md) which map any Dart type to a supported SQL type.

| Dart type   | Column              | Corresponding SQLite type                                                                            |
| ----------- | ------------------- | ---------------------------------------------------------------------------------------------------- |
| `int`       | `#!dart integer()`  | `#!sql INTEGER`                                                                                      |
| `BigInt`    | `#!dart int64()`    | `#!sql INTEGER` (useful for large values on the web)                                                 |
| `double`    | `#!dart real()`     | `#!sql REAL`                                                                                         |
| `bool`      | `#!dart boolean()`  | `#!sql INTEGER`, which a `CHECK` to only allow `0` or `1`                                            |
| `String`    | `#!dart text()`     | `#!sql TEXT`                                                                                         |
| `DateTime`  | `#!dart dateTime()` | `#!sql INTEGER` (default) or `TEXT` depending on [options](#datetime)                                |
| `Uint8List` | `#!dart blob()`     | `#!sql BLOB`                                                                                         |
| `enum`      | `#!dart intEnum()`  | `#!sql INTEGER` (more information available [here](../type_converters.md#implicit-enum-converters)). |
| `enum`      | `#!dart textEnum()` | `#!sql TEXT` (more information available [here]("../type_converters.md#implicit-enum-converters")).  |

!!! note "JSON Serialization"
    
    The way drift maps Dart types to SQL types is independent of how it serializes data to JSON.  
    For example, Dart `bool` values are stored as `0` or `1` in the database, but as `true` or `false` in JSON.

??? note "Custom Column Types"

    To support database engines with additional column types, custom types can be used - this feature is primarily aimed towards users porting drift to a different database system


### Optional Columns

Drift adopts Dart's non-nullable by default approach.  
If you do want to make a column nullable, use `nullable()`:

{{ load_snippet('nnbd','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Columns in Dart-defined tables default to `NOT NULL` in SQL. Omitting values during an insert will throw an exception.

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

**Key Differences**:

- `withDefault` will store the default value in the database, while `clientDefault` will generate the default value on the client side.

- For constant values, like `false`, `true`, or `0`, `withDefault` is more efficient.
`clientDefault` is more flexible for dynamic values like `DateTime.now()` or `Uuid().v4()`.

- Changing the default value for a column with `withDefault` requires a schema migration, while `clientDefault` allows you to change the default value without a schema migration.

### Checks (Data Validation)

Use the `check` method to create a constraint that validates the column's value.
This method takes a Boolean expression as an argument and is evaluated for each insert or update.

For example, the following code ensures that the `age` column is always greater than `0`:

{{ load_snippet('check','lib/snippets/dart_api/tables.dart.excerpt.json') }}

To add, remove, or modify a check constraint after table creation, you must write a [schema migration](../Migrations/index.md).

See the [Expressions](../Expressions/index.md) page for more on writing expressions.

!!! info "Thrown Exceptions"

    Validation/Checks are enforced at the database level.  
    Creating a `User` dataclass with an `age` of `-1` will not throw an exception. Only when that data is inserted into the database will an exception be thrown.

!!! note "Recusive Checks"

    The dart analyzer may report a [`recursive_getters`](https://dart.dev/tools/linter-rules/recursive_getters) error when using a column in a check expression.  
    This can be safely ignored, as this code is never executed.


### Unique Columns

#### Single Column

Use the `unique()` method to enforce that a column must contain unique values.
For example, the following code ensures that each users `username` is unique:

{{ load_snippet('unique-column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

#### Multiple Columns

If you want to enforce a combination of columns to be unique, override the `uniqueKeys` getter in your table class.  
For example, if one wanted to ensure that an author can't write two books with the same title:

{{ load_snippet('unique-table','lib/snippets/dart_api/tables.dart.excerpt.json') }}

### Foreign Keys

See the [References](../References/index.md) page for more information on foreign keys.

### Store Additional Types

Use the `map()` method to provide a Type Converter for a column.
This will allow you to store any type in a column that drift doesn't support out of the box.

{{ load_snippet('table','lib/snippets/type_converters/converters.dart.excerpt.json') }}

For more information on how to write a type converter, see the [Type Converters](../type_converters.md) page.


!!! note "Isn't `customType()` for for this?"

    **No.**
    Drift has a confusingly named `customType()` which typically shouldn't be used.  
    The intended use case for this method is to add support for columns that are not supported by drift out of the box. (e.g. `drift_postgres` uses this method add support for `uuid` columns).

### `BigInt`


Use `int64()` to store large integers in Dart.
This will preserve precision in JavaScript-compiled apps. 

!!! note annotate "When to use `int64()`"

    The standard `integer()` column suffices for most cases, especially non-web apps.  
    Only use `int64()` for web apps with values exceeding 2^52. (1)

1.  This is a huge number, 4,503,599,627,370,496 to be exact. so you're unlikely to reach this limit in practice. 
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



1. **UNIX Timestamp** [Default]:  

    DateTime values are stored in seconds as an SQL `#!sql INTEGER` containing the Unix timestamp (e.g. `1722169674`).  
    This default behavior can be changed by setting the `store_date_time_values_as_text` [build option](../Generation options/index.md).  

    <!-- | -->
**Pros**
    
    * **Performance**: Intergers are more efficient to store and compare than textual representations.  
    
    **Cons**:  

    * **No Timezones**: All local time information is lost.
    
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


Drift stores `DateTime` values as unix timestamps by default. This can be changed by setting the `store_date_time_values_as_text` [build option](../Generation options/index.md).

Migrating between the two modes is possible but requires a [manual migration](#migrating-between-the-two-modes).

### Column Names


Column names are derived from Dart getter names, converted to snake_case by default. The `case_from_dart_to_sql`[build option](../Generation Options/index.md) allows you to change this default case convention (e.g., to pascal case or camel case). For individual columns, use the named method to set a completely custom name, overriding the default naming convention.

{{ load_snippet('column-name','lib/snippets/dart_api/tables.dart.excerpt.json') }}



### Generated Columns

Generated columns are columns whose values are computed from other columns in the same row.

{{ load_snippet('generated-column','lib/snippets/dart_api/tables.dart.excerpt.json') }}

These columns can be used in queries like any other column. In the example above we added an index which will be used by sqlite to quickly sort orders by their total.

There are two types of generated columns:

1. **Virtual Columns**: These columns are computed on the fly when queried. They are not stored in the database.
2. **Stored Columns**: These columns are computed when a row is inserted or updated and stored in the database.

By default, drift creates virtual columns. To create a stored column, set the `stored` parameter to `true`.

!!! note "What should I use?"

    Using virtual columns is more efficient as they don't require additional storage. However, they are slower to query as they are computed on the fly. See the [sqlite documentation](https://sqlite.org/gencol.html) for more information.

# Custom Column Constraints
Some column and table constraints aren't supported through drift's Dart api. This includes the collation of columns, which you can apply using `customConstraint`:

Applying a `customConstraint` will override all other constraints that would be included by default. In particular, that means that we need to also include the `NOT NULL` constraint again.

{{ load_snippet('custom-col-constraint','lib/snippets/dart_api/tables.dart.excerpt.json') }}

You can also add table-wide constraints by overriding the `customConstraints` getter in your table class.