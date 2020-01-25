---
title: "Type converters"
description: Store more complex data in columns with type converters
aliases:
 - /type_converters
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
  Preferences mapToDart(String fromDb) {
    if (fromDb == null) {
      return null;
    }
    return Preferences.fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String mapToSql(Preferences value) {
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
also works with [compiled custom queries]({{ "/queries/custom" | absolute_url }}).

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