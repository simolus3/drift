---

title: Type Converters
description: Store more complex data in columns with type converters

---

Drift offers support for various types by default, but there are times when you need to store more complex data. This can be accomplished by using `TypeConverters`.


??? example "Example Class"

    To demonstrate the use of a type converter, we will use the following class as an example:

    {{ load_snippet('start','lib/snippets/type_converters/converters.dart.excerpt.json', indent=4) }}

Define a class which extends `TypeConverter` with 2 generic types: 

- The first type is the Dart type you want to store in the database (e.g. `Preferences`).
- The second type is the type you want to store in the database (e.g `String`).


{{ load_snippet('converter','lib/snippets/type_converters/converters.dart.excerpt.json') }}

The `fromSql` method is used to read data from the database, while the `toSql` method is used to write data to the database.

Use the `map` method to add the converter to a column:

{{ load_snippet('table','lib/snippets/type_converters/converters.dart.excerpt.json') }}

The generated `User` class will then have a `preferences` column of type
`Preferences`. Drift will automatically take care of storing and loading
the object in `select`, `update` and `insert` statements.

!!! warning "Caution with equality"

    Implement `operator ==` and `hashCode` on classes that are not comparable by value.

### JSON Converters

Since applying type converters for JSON conversion is so common, drift provides a helper
for that. For instance, we could declare the type converter as a field in the
`Preferences` class:

{{ load_snippet('simplified','lib/snippets/type_converters/converters.dart.excerpt.json') }}

### Enum Converters

Drift provides 2 helper functions to make it easier to store enums in the database.
- To store an enum as an integer, use `intEnum`, which will store the enum as its index.
- To store an enum as a string, use `textEnum`, which will store the enum as its name.

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

    Be extremely vigilant when modifying your enum values.  

    - **`intEnum`**: If the order of the enum values is changed, the database will not be able to find the value anymore.
    - **`textEnum`**: If the name of the enum values is changed, the database will not be able to find the value anymore.
    
    For instance, if we modify `Status` enum to include another entry:
    ```dart
    enum Status {
      none,
      starting, // new!
      running,
      stopped,
      paused
    }
    ```
    Tasks that were previously stored with `Status.running` will now be read as `Status.starting`!

    ??? tip "Tip for using IntEnum"
        When using an IntEnum, you can guard against changes to the enum values by adding a check in your code.

        ```dart
        final _ = (){
            assert(Status.none.index == 0);
            assert(Status.running.index == 1);
            assert(Status.stopped.index == 2);
            assert(Status.paused.index == 3);
        }();
        ```
        This way you can ensure that if the order of the enum values is changed, the above assertions will throw an exception.

Also note that you can't apply another type converter on a column declared with an enum converter.

## Type Converters and JSON Serialization

By default, type converters are used solely for converting data from Dart into the database format; they do not affect the serialization of values to and from JSON.   
If you want to apply the same conversion to JSON as well, make your type converter mix-in the
`JsonTypeConverter` class.

You can also override the `toJson` and `fromJson` methods to customize serialization as long as the types
stay the compatible.

!!! note "JSON Converter"

    The built-in `TypeConverter.json` method returns a type converter that implements `JsonTypeConverter`.
    No additional steps are required to apply the converter to JSON serialization.

### Distinct Serialization for JSON and SQL

If the JSON type you want to serialize to is different to the SQL type you're
mapping to, you can mix-in `JsonTypeConverter2` instead.
For instance, say you have a type converter mapping to a complex Dart type
`MyObject`. In SQL, you might want to store this as an `String`. But when
serializing to JSON, you may want to use a `Map<String, Object?>`. Here, simply
add the `JsonTypeConverter2<MyObject, String, Map<String, Object?>>` mixin to
your type converter.

As an alternative to using JSON type converters, you can use a custom [`ValueSerializer`](https://drift.simonbinder.eu/api/drift/valueserializer-class)
and pass it to the serialization methods.

## Type Converters in Expressions

Type Converters are not applied automatically when creating your own [expressions]('Dart API/expressions.md').
For example, filtering for values with [`column.equals`](https://drift.simonbinder.eu/api/drift/expression/equals)
will compare not apply the type converter, you'd be comparing the underlying database values.

On columns with type converters, [`equalsValue`](https://drift.simonbinder.eu/api/drift/generatedcolumnwithtypeconverter/equalsvalue)
can be used instead. Unlike `equals`, `equasValue` will apply the converter before emtting a comparison in SQL.
If you need to apply the converter for other comparisons as well, you can do that manually with `column.converter.toSql`.