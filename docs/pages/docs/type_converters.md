---
data:
  title: "Type converters"
  weight: 5
  description: Store more complex data in columns with type converters
aliases:
 - /type_converters
path: /docs/advanced-features/type_converters/
template: layouts/docs/single
---

Drift supports a variety of types out of the box, but sometimes you need to store more complex data.
You can achieve this by using `TypeConverters`. In this example, we'll use the the
[json_serializable](https://pub.dev/packages/json_annotation) package to store a custom object in a
text column. Drift supports any Dart type for which you provide a `TypeConverter`, we're using that
package here to make the example simpler.

{% assign dart = 'package:drift_docs/snippets/type_converters/converters.dart.excerpt.json' | readString | json_decode %}

## Using converters in Dart

{% include "blocks/snippet" snippets = dart name = 'start' %}

Next, we have to tell drift how to store a `Preferences` object in the database. We write
a `TypeConverter` for that:

{% include "blocks/snippet" snippets = dart name = 'converter' %}

Finally, we can use that converter in a table declaration:

{% include "blocks/snippet" snippets = dart name = 'table' %}

The generated `User` class will then have a `preferences` column of type
`Preferences`. Drift will automatically take care of storing and loading
the object in `select`, `update` and `insert` statements. This feature
also works with [compiled custom queries]({{ "/queries/custom" | absUrl }}).

{% block "blocks/alert" title="Caution with equality" color="warning" %}
If your converter returns an object that is not comparable by value, the generated dataclass will not
be comparable by value. Consider implementing `==` and `hashCode` on those classes.
{% endblock %}

Since applying type converters for JSON conversion is so common, drift provides a helper
for that. For instance, we could declare the type converter as a field in the
`Preferences` class:

{% include "blocks/snippet" snippets = dart name = 'simplified' %}

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

{% block "blocks/alert" title="Caution with enums" color="warning" %}
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
{% endblock %}

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

{% block "blocks/alert" title="Caution with enums" color="warning" %}
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
{% endblock %}

Also note that you can't apply another type converter on a column declared with an enum converter.

## Using converters in drift {#using-converters-in-moor}

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

When using type converters in drift files, we recommend the [`apply_converters_on_variables`]({{ "Generation options/index.md" | pageUrl }})
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

## Type converters and json serialization

By default, type converters only apply to the conversion from Dart to the database. They don't impact how
values are serialized to and from JSON.
If you want to apply the same conversion to JSON as well, make your type converter mix-in the
`JsonTypeConverter` class.
You can also override the `toJson` and `fromJson` methods to customize serialization as long as the types
stay the compatible.
The type converter returned by `TypeConverter.json` already implements `JsonTypeConverter`, so it will
apply to generated row classes as well.

If the JSON type you want to serialize to is different to the SQL type you're
mapping to, you can mix-in `JsonTypeConverter2` instead.
For instance, say you have a type converter mapping to a complex Dart type
`MyObject`. In SQL, you might want to store this as an `String`. But when
serializing to JSON, you may want to use a `Map<String, Object?>`. Here, simply
add the `JsonTypeConverter2<MyObject, String, Map<String, Object?>>` mixin to
your type converter.

As an alternative to using JSON type converters, you can use a custom [`ValueSerializer`](https://drift.simonbinder.eu/api/drift/valueserializer-class)
and pass it to the serialization methods.
