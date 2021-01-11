---
title: "Dart tables"
description: Further information on Dart tables
weight: 150
---

{{% pageinfo %}}
__Prefer sql?__ If you prefer, you can also declare tables via `CREATE TABLE` statements.
Moor's sql analyzer will generate matching Dart code. [Details]({{< ref "starting_with_sql.md" >}}).
{{% /pageinfo %}}

As shown in the [getting started guide]({{<relref "_index.md">}}), sql tables can be written in Dart:
```dart
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}
```

In this article, we'll cover some advanced features of this syntax.

## Names

By default, moor uses the `snake_case` name of the Dart getter in the database. For instance, the
table
```dart
class EnabledCategories extends Table {
    IntColumn get parentCategory => integer()();
    // ..
}
```

Would be generated as `CREATE TABLE enabled_categories (parent_category INTEGER NOT NULL)`.

To override the table name, simply override the `tableName` getter. An explicit name for
columns can be provided with the `named` method:
```dart
class EnabledCategories extends Table {
    String get tableName => 'categories';

    IntColumn get parentCategory => integer().named('parent')();
}
```

The updated class would be generated as `CREATE TABLE categories (parent INTEGER NOT NULL)`.

To update the name of a column when serializing data to json, annotate the getter with 
[`@JsonKey`](https://pub.dev/documentation/moor/latest/moor/JsonKey-class.html).

You can change the name of the generated data class too. By default, moor will stip a trailing
`s` from the table name (so a `Users` table would have a `User` data class).
That doesn't work in all cases though. With the `EnabledCategories` class from above, we'd get
a `EnabledCategorie` data class. In those cases, you can use the [`@DataClassName`](https://pub.dev/documentation/moor/latest/moor/DataClassName-class.html)
annotation to set the desired name.

## Nullability

By default, columns may not contain null values. When you forgot to set a value in an insert,
an exception will be thrown. When using sql, moor also warns about that at compile time.

If you do want to make a column nullable, just use `nullable()`:
```dart
class Items {
    IntColumn get category => integer().nullable();
    // ...
}
```

## Default values

You can set a default value for a column. When not explicitly set, the default value will
be used when inserting a new row. To set a constant default value, use `withDefault`:

```dart
class Preferences extends Table {
  TextColumn get name => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
}
```

When you later use `into(preferences).insert(PreferencesCompanion.forInsert(name: 'foo'));`, the new
row will have its `enabled` column set to false (and not to null, as it normally would).
Note that columns with a default value (either through `autoIncrement` or by using a default), are
still marked as `@required` in generated data classes. This is because they are meant to represent a
full row, and every row will have those values. Use companions when representing partial rows, like
for inserts or updates.

Of course, constants can only be used for static values. But what if you want to generate a dynamic
default value for each column? For that, you can use `clientDefault`. It takes a function returning
the desired default value. The function will be called for each insert. For instance, here's an
example generating a random Uuid using the `uuid` package:
```dart
final _uuid = Uuid();

class Users extends Table {
    TextColumn get id => text().clientDefault(() => _uuid.v4())();
    // ...
}
```

Don't know when to use which? Prefer to use `withDefault` when the default value is constant, or something
simple like `currentDate`. For more complicated values, like a randomly generated id, you need to use
`clientDefault`. Internally, `withDefault` writes the default value into the `CREATE TABLE` statement. This
can be more efficient, but doesn't support dynamic values.

## Primary keys

If your table has an `IntColumn` with an `autoIncrement()` constraint, moor recognizes that as the default
primary key. If you want to specify a custom primary key for your table, you can override the `primaryKey`
getter in your table:

```dart
class GroupMemberships extends Table {
  IntColumn get group => integer()();
  IntColumn get user => integer()();

  @override
  Set<Column> get primaryKey => {group, user};
}
```

Note that the primary key must essentially be constant so that the generator can recognize it. That means:

- it must be defined with the `=>` syntax, function bodies aren't supported
- it must return a set literal without collection elements like `if`, `for` or spread operators

## Supported column types

Moor supports a variety of column types out of the box. You can store custom classes in columns by using
[type converters]({{<relref "../Advanced Features/type_converters.md">}}).

| Dart type    | Column        | Corresponding SQLite type                           |
|--------------|---------------|-----------------------------------------------------|
| `int`        | `integer()`   | `INTEGER`                                           |
| `double`     | `real()`      | `REAL`                                              |
| `boolean`    | `boolean()`   | `INTEGER`, which a `CHECK` to only allow `0` or `1` |
| `String`     | `text()`      | `TEXT`                                              |
| `DateTime`   | `dateTime()`  | `INTEGER` (Unix timestamp in seconds)               |
| `Uint8List`  | `blob()`      | `BLOB`                                              |

Note that the mapping for `boolean`, `dateTime` and type converters only applies when storing records in
the database.
They don't affect JSON serialization at all. For instance, `boolean` values are expected as `true` or `false`
in the `fromJson` factory, even though they would be saved as `0` or `1` in the database.
If you want a custom mapping for JSON, you need to provide your own [`ValueSerializer`](https://pub.dev/documentation/moor/latest/moor/ValueSerializer-class.html).

## Custom constraints

Some column and table constraints aren't supported through moor's Dart api. This includes `REFERENCES` clauses on columns, which you can set
through `customConstraint`:

```dart
class GroupMemberships extends Table {
  IntColumn get group => integer().customConstraint('NOT NULL REFERENCES groups (id)')();
  IntColumn get user => integer().customConstraint('NOT NULL REFERENCES users (id)')();

  @override
  Set<Column> get primaryKey => {group, user};
}
```

Applying a `customConstraint` will override all other constraints that would be included by default. In
particular, that means that we need to also include the `NOT NULL` constraint again.

You can also add table-wide constraints by overriding the `customConstraints` getter in your table class.
