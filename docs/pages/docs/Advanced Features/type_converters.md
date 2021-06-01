---
data:
  title: "Type converters"
  description: Store more complex data in columns with type converters
aliases:
 - /type_converters
template: layouts/docs/single
---

Moor supports a variety of types out of the box, but sometimes you need to store more complex data.
You can achieve this by using `TypeConverters`. In this example, we'll use the the 
[json_serializable](https://pub.dev/packages/json_annotation) package to store a custom object in a
text column. Moor supports any Dart type for which you provide a `TypeConverter`, we're using that
package here to make the example simpler.

## Using converters in Dart

```dart
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart' as j;
import 'package:moor/moor.dart';

part 'database.g.dart';

@j.JsonSerializable()
class Preferences {
  bool receiveEmails;
  String selectedTheme;

  Preferences(this.receiveEmails, this.selectedTheme);

  factory Preferences.fromJson(Map<String, dynamic> json) =>
      _$PreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$PreferencesToJson(this);
}
```

Next, we have to tell moor how to store a `Preferences` object in the database. We write
a `TypeConverter` for that:
```dart
// stores preferences as strings
class PreferenceConverter extends TypeConverter<Preferences, String> {
  const PreferenceConverter();
  @override
  Preferences? mapToDart(String? fromDb) {
    if (fromDb == null) {
      return null;
    }
    return Preferences.fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String? mapToSql(Preferences? value) {
    if (value == null) {
      return null;
    }

    return json.encode(value.toJson());
  }
}
```

Finally, we can use that converter in a table declaration:
```dart
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  TextColumn get preferences =>
      text().map(const PreferenceConverter()).nullable()();
}
```

The generated `User` class will then have a `preferences` column of type 
`Preferences`. Moor will automatically take care of storing and loading
the object in `select`, `update` and `insert` statements. This feature
also works with [compiled custom queries]({{ "/queries/custom" | absURL }}).

{% block "blocks/alert" title="Caution with equality" color="warning" %}
> If your converter returns an object that is not comparable by value, the generated dataclass will not
  be comparable by value.
{% endblock %}

### Implicit enum converters

A common scenario for type converters is to map between enums and integers by representing enums
as their index. Since this is so common, moor has the integrated `intEnum` column type to make this
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
> It can be easy to accidentally invalidate your database by introducing another enum value.
  For instance, let's say we inserted a `Task` into the database in the above example and set its
  `Status` to `running` (index = 1).
  Now we `Status` enum to include another entry:
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

Also note that you can't apply another type converter on a column declared with an enum converter.

## Using converters in moor

Since moor 2.4, type converters can also be used inside moor files.
Assuming that the `Preferences` and `PreferenceConverter` are contained in
`preferences.dart`, that file can imported into moor for the type converter to
be available.

```sql
import 'preferences.dart';

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  preferences TEXT MAPPED BY `const PreferenceConverter()`
);
```

When using type converters in moor files, we recommend the [`apply_converters_on_variables`]({{ "builder_options.md" | pageUrl }})
build option. This will also apply the converter from Dart to SQL, for instance if used on variables: `SELECT * FROM users WHERE preferences = ?`.
With that option, the variable will be inferred to `Preferences` instead of `String`.

Moor files also have special support for implicit enum converters:

```sql
import 'status.dart';

CREATE TABLE tasks (
  id INTEGER NOT NULL PRIMARY KEY,
  status ENUM(Status)
);
```

Of course, the warning about automatic enum converters also applies to moor files.
