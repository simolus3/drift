---
data:
  title: "Custom row classes"
  description: >-
    Use your own classes as data classes for moor tables
template: layouts/docs/single
---

For each table declared in Dart or in a moor file, `moor_generator` generates a row class (sometimes also referred to as _data class_)
to hold a full row and a companion class for updates and inserts.
This works well for most cases: Moor knows  what columns your table has, and it can generate a simple class for all of that.
In some cases, you might want to customize the generated classes though.
For instance, you might want to add a mixin, let it extend another class or interface, or use other builders like
`json_serializable` to customize how it gets serialized to json.

Starting from moor version 4.3, it is possible to use your own classes as data classes.

## Using custom classes

To use a custom row class, simply annotate your table definition with `@UseRowClass`.

```dart
@UseRowClass(User)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get birthdate => dateTime()();
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
- Each constructor argument must have the name of a moor column
  (matching the getter name in the table definition)
- The type of a constructor argument must be equal to the type of a column,
  including nullability and applied type converters.

On the other hand, note that:

- A custom row class can have additional fields and constructor arguments, as
  long as they're not required. Moor will ignore those parameters when mapping
  a database row.
- A table can have additional columns not reflected in a custom data class.
  Moor will simply not load those columns when mapping a row.

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
    return {
      'id': Variable<int>(id),
      'name': Variable<String>(name),
      'birth_date': Variable<DateTime>(birthDate),
    };
  }
}
```

In a future moor version, the generator might be able to help you write the `toColumns` implementation -
follow [#1134](https://github.com/simolus3/moor/issues/1134) for updates.

### When custom classes make sense

The default moor-generated classes are a good default for most applications.
In some advanced use-cases, custom classes can be a better alternative though:

- Reduce generated code size: Due to historical reasons and backwards-compatibility, moor's classes
  contain a number of methods for json serialization and `copyWith` that might not be necessary
  for all users.
  Custom row classes can reduce bloat here.
- Custom superclasses: A custom row class can extend and class and implement or mix-in other classes
  as desired.
- Other code generators: Since you control the row class, you can make better use of other builders like
  `json_serializable` or `built_value`.

## Limitations

These restrictions will be gradually lifted in upcoming moor versions. Follow [#1134](https://github.com/simolus3/moor/issues/1134) for details.

For now, this feature is subject to the following limitations:

- Only tables defined in Dart can use custom data classes, tables from moor files are not supported yet
- At the moment, moor only recognizes the unnamed constructor to map rows back to your class
- Custom row classes can only be used for tables, not for custom result sets of compiled queries
- Implementing `toColumns` can be error-prone for unexpected column names or when using type converters.
  A future moor version could help you implement `toColumns` - until then, the recommendation is to always
  use moor-generated companions.
