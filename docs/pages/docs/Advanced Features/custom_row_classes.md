---
data:
  title: "Custom row classes"
  description: >-
    Use your own classes as data classes for drift tables
template: layouts/docs/single
---

For each table declared in Dart or in a drift file, `drift_dev` generates a row class (sometimes also referred to as _data class_)
to hold a full row and a companion class for updates and inserts.
This works well for most cases: Drift knows  what columns your table has, and it can generate a simple class for all of that.
In some cases, you might want to customize the generated classes though.
For instance, you might want to add a mixin, let it extend another class or interface, or use other builders like
`json_serializable` to customize how it gets serialized to json.

Starting from moor version 4.3 (and in drift), it is possible to use your own classes as data classes.

## Using custom classes

To use a custom row class, simply annotate your table definition with `@UseRowClass`.

```dart
@UseRowClass(User)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get birthday => dateTime()();
}

class User {
  final int id;
  final String name;
  final DateTime birthDate;

  User({required this.id, required this.name, required this.birthDate});
}
```

A row class must adhere to the following requirements:

- It must have an unnamed constructor
- Each constructor argument must have the name of a drift column
  (matching the getter name in the table definition)
- The type of a constructor argument must be equal to the type of a column,
  including nullability and applied type converters.

On the other hand, note that:

- A custom row class can have additional fields and constructor arguments, as
  long as they're not required. Drift will ignore those parameters when mapping
  a database row.
- A table can have additional columns not reflected in a custom data class.
  Drift will simply not load those columns when mapping a row.

### Using another constructor

By default, drift will use the default, unnamed constructor to map a row to the class.
If you want to use another constructor, set the `constructor` parameter on the
`@UseRowClass` annotation:

```dart
@UseRowClass(User, constructor: 'fromDb')
class Users extends Table {
  // ...
}

class User {
  final int id;
  final String name;
  final DateTime birthDate;

  User.fromDb({required this.id, required this.name, required this.birthDate});
}
```

### Existing row classes in drift files

To use existing row classes in drift files, use the `WITH` keyword at the end of the
table declaration. Also, don't forget to import the Dart file declaring the row
class into the drift file.

```sql
import 'user.dart'; -- or what the Dart file is called

CREATE TABLE users(
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  birth_date DATETIME NOT NULL
) WITH User;
```

## Inserts and updates with custom classes

In most cases, generated companion classes are the right tool for updates and inserts.
If you prefer to use your custom row class for inserts, just make it implement `Insertable<T>`, where
`T` is the name of your row class itself.
For instance, the previous class could be changed like this:

```dart
class User implements Insertable<User> {
  final int id;
  final String name;
  final DateTime birthDate;

  User({required this.id, required this.name, required this.birthDate});

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      birthDate: Value(birthDate),
    ).toColumns(nullToAbsent);
  }
}
```

## When custom classes make sense

The default drift-generated classes are a good default for most applications.
In some advanced use-cases, custom classes can be a better alternative though:

- Reduce generated code size: Due to historical reasons and backwards-compatibility, drift's classes
  contain a number of methods for json serialization and `copyWith` that might not be necessary
  for all users.
  Custom row classes can reduce bloat here.
- Custom superclasses: A custom row class can extend and class and implement or mix-in other classes
  as desired.
- Other code generators: Since you control the row class, you can make better use of other builders like
  `json_serializable` or `built_value`.

## Limitations

These restrictions will be gradually lifted in upcoming drift versions. Follow [#1134](https://github.com/simolus3/drift/issues/1134) for details.

For now, this feature is subject to the following limitations:

- In drift files, you can only use the default unnamed constructor
- Custom row classes can only be used for tables, not for custom result sets of compiled queries

