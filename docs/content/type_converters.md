---

title: Type converters
description: Store more complex data in columns with type converters

---

Drift supports a variety of types out of the box, but sometimes you need to store more complex data.
You can achieve this by using `TypeConverters`. In this example, we'll use the the
[json_serializable](https://pub.dev/packages/json_annotation) package to store a custom object in a
text column. Drift supports any Dart type for which you provide a `TypeConverter`, we're using that
package here to make the example simpler.

## Using converters in Dart

<Snippet href="/lib/src/snippets/type_converters/converters.dart" name="start" />

Next, we have to tell drift how to store a `Preferences` object in the database. We write
a `TypeConverter` for that:

<Snippet href="/lib/src/snippets/type_converters/converters.dart" name="converter" />

This is using the `JsonTypeConverter2` classes, the original ones are [deprecated](#type-converters-and-json-serialization)
and will be removed in the next major drift version.

Finally, we can use that converter in a table declaration:

<Snippet href="/lib/src/snippets/type_converters/converters.dart" name="table" />

The generated `User` class will then have a `preferences` column of type
`Preferences`. Drift will automatically take care of storing and loading
the object in `select`, `update` and `insert` statements. This feature
also works with [compiled custom queries]("/queries/custom").

!!! warning "Common type converter issues"

    If your converter returns an object that is not comparable by value, the generated dataclass will not
    be comparable by value. Consider implementing `==` and `hashCode` on those classes.

    Also note that drift generates `part` files by default, which currently can't have their own imports.
    For this reason, if you define tables in another file than your database file, you'll have to manually
    add imports to type converters to that file.
    [Modular code generation](generation_options/modular.md) can fix this issue too.

Since applying type converters for JSON conversion is so common, drift provides a helper
for that. For instance, we could declare the type converter as a field in the
`Preferences` class:

<Snippet href="/lib/src/snippets/type_converters/converters.dart" name="simplified" />

!!! info "Why JSON converters?"

    By default, type converters are only applied to the mapping from Dart to and from SQL.
    Drift also generates `fromJson` and `toJson` methods on data classes, and those don't
    apply type converters by default.
    By mixing in `JsonTypeConverter`, you tell drift that the converter should also be considered
    for JSON serialization.

### Using JSONB

Since version 3.45.0, SQLite supports its own [JSONB](https://sqlite.org/jsonb.html) representation for
JSON values. As the linked documentation page mentions:

>  The advantage of JSONB over ordinary text RFC 8259 JSON is that JSONB is both slightly smaller (by between 5% and 10% in most cases) and can be processed in less than half the number of CPU cycles. The built-in JSON SQL functions of SQLite can accept either ordinary text JSON or the binary JSONB encoding for any of their JSON inputs.

When you use drift with SQLite, it may thus be helpful to use this JSONB format. Starting from version 2.24.0, drift
has built-in support for that. First, use `TypeConverter.jsonb` to create a JSONB-based converter in Dart.
Re-using the `Preferences` class from above, such a converter may look like this:

<Snippet href="/lib/src/snippets/type_converters/converters.dart" name="jsonb" />

It can then be applied to binary columns:

```dart
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  BlobColumn get preferences =>
      blob().map(Preferences.binaryConverter).nullable()();
}
```

To determine whether using JSONB can be an advantage over textual JSON for you, keep the following things in mind:

1. The mentioned "processing in half the number of CPU cycles" aspect refers to processing _within_ SQLite.
   For typical drift usages, SQLite will not process JSON at all. Only when you are extracting individual paths
   from JSON objects in SQL (or using other JSON operators) will SQLite actually have to process JSON.
2. JSONB converters use a Dart implementation of the JSONB format as understood by SQLite.
   Given that the JSON decoder from `dart:convert` is highly optimized and backed by native code on some platforms,
   using JSONB will likely not yield significant performance gains when reading columns in Dart.
3. Using JSONB can make your database code less portable, as SQLite uses its own JSONB format not natively understood
   by most other tools. You can use the `json()` function in SQL to convert it to regular JSON though.

For these reasons, we recommend sticking with the standard text-based JSON format unless you are directly processing
these values in SQL queries.

### Implicit enum converters

A common scenario for type converters is to map between enums and integers by representing enums
as their index. Since this is so common, drift has the integrated `intEnum` column type to make this
easier.

```dart
enum Status {
  none,
  running,
  stopped,
  paused
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get status => intEnum<Status>()();
}
```

!!! warning "Caution with enums"


    It can be easy to accidentally invalidate your database by introducing another enum value.
    For instance, let's say we inserted a `Task` into the database in the above example and set its
    `Status` to `running` (index = 1).
    Now we modify `Status` enum to include another entry:
    ```dart
    enum Status {
      none,
      starting, // new!
      running,
      stopped,
      paused
    }
    ```
    When selecting the task, it will now report as `starting`, as that's the new value at index 1.
    For this reason, it's best to add new values at the end of the enumeration, where they can't conflict
    with existing values. Otherwise you'd need to bump your schema version and run a custom update statement
    to fix this.




If you prefer to store the enum as a text, you can use `textEnum` instead.

```dart
enum Status {
   none,
   running,
   stopped,
   paused
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get status => textEnum<Status>()();
}
```

!!! warning "Caution with enums"


    It can be easy to accidentally invalidate your database by renaming your enum values.
    For instance, let's say we inserted a `Task` into the database in the above example and set its
    `Status` to `running`.
    Now we modify `Status` enum to rename `running` into `processing`:
    ```dart
    enum Status {
      none,
      processing,
      stopped,
      paused
    }
    ```
    When selecting the task, it won't be able to find the enum value `running` anymore, and will throw an error.

    For this reason, it's best to not modify the name of your enum values. Otherwise you'd need to bump your schema version and run a custom update statement to fix this.




Also note that you can't apply another type converter on a column declared with an enum converter.

## Using converters in drift files

Type converters can also be used inside drift files.
Assuming that the `Preferences` and `PreferenceConverter` are contained in
`preferences.dart`, that file can imported into drift for the type converter to
be available.

```sql
import 'preferences.dart';

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  preferences TEXT MAPPED BY `const PreferenceConverter()`
);
```

When using type converters in drift files, we recommend the [`apply_converters_on_variables`](generation_options/index.md)
build option. This will also apply the converter from Dart to SQL, for instance if used on variables: `SELECT * FROM users WHERE preferences = ?`.
With that option, the variable will be inferred to `Preferences` instead of `String`.

Drift files also have special support for implicit enum converters:

```sql
import 'status.dart';

CREATE TABLE tasks (
  id INTEGER NOT NULL PRIMARY KEY,
  status ENUM(Status)
);
```

Of course, the warning about automatic enum converters also applies to drift files.

## Type converters and JSON serialization

By default, type converters only apply to the conversion from Dart to the database. They don't impact how
values are serialized to and from JSON.
If you want to apply the same conversion to JSON as well, make your type converter mix-in the
`JsonTypeConverter2` class.
You can also override the `toJson` and `fromJson` methods to customize serialization as long as the types
stay the compatible.
The type converter returned by `TypeConverter.json2` already implements `JsonTypeConverter2`, so it will
apply to generated row classes as well.

In addition to `json2` and `JsonTypeConverter2`, where are the legacy `TypeConverter.json`
and `JsonTypeConverter` classes.
These differ from the v2 variants in that they must always emit strings when mapping to JSON.
This is an issue for the common case where you have a complex Dart type (e.g. `MyObject`) that
can be mapped to a `Map<String, Object?>` in JSON.
In SQL, you might want to store this object as a `String` by first mapping it to a `Map` and then
encoding that as JSON.
But when serializing the whole data class for the table to JSON, it's typically undesirable to have
`MyObject` serialized as a string (effectively applying JSON serialization twice).

The v2 variants of the JSON type converters have a separate type parameter that can be independent of
the type in SQL, which fixes this issue.

As an alternative to using JSON type converters, you can use a custom [`ValueSerializer`](https://drift.simonbinder.eu/api/drift/valueserializer-class)
and pass it to the serialization methods.

## Type converters and SQL

In database rows, columns to which a type converter has been applied are storing the result of
`toSql()`. Drift will apply the type converter automatically when reading or writing rows, but they
are not applied automatically when creating your own [expressions]('dart_api/expressions.md').
For example, filtering for values with [`column.equals`](https://drift.simonbinder.eu/api/drift/expression/equals)
will compare not apply the type converter, you'd be comparing the underlying database values.

On columns with type converters, [`equalsValue`](https://drift.simonbinder.eu/api/drift/generatedcolumnwithtypeconverter/equalsvalue)
can be used instead - unlike `equals`, `equasValue` will apply the converter before emitting a comparison in SQL.
If you need to apply the converter for other comparisons as well, you can do that manually with `column.converter.toSql`.

For variables used in queries that are part of a [drift file]('sql_api/drift_files.md'), type converters will be
applied by default if the `apply_converters_on_variables` [builder option]('generation_options/index.md') is enabled (which it is by default).

When reading custom expressions that should have a type converter attached to them, you'd have to first read the underlying
SQL value and then apply your type converter manually.
To map nullable values through an otherwise non-nullable type converter, you can use the `NullAwareTypeConverter.wrapFromSql` utility method.
