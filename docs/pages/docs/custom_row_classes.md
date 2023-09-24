---
data:
  title: "Custom row classes"
  weight: 6
  description: >-
    Use your own classes as data classes for drift tables
template: layouts/docs/single

path: docs/advanced-features/custom_row_classes/
---

For each table declared in Dart or in a drift file, `drift_dev` generates a row class (sometimes also referred to as _data class_)
to hold a full row and a companion class for updates and inserts.
This works well for most cases: Drift knows  what columns your table has, and it can generate a simple class for all of that.
In some cases, you might want to customize the generated classes though.
For instance, you might want to add a mixin, let it extend another class or interface, or use other builders like
`json_serializable` to customize how it gets serialized to json.

As a solution, drift allows you to use your own classes as data classes for the database.

## Using custom classes

To use a custom row class, simply annotate your table definition with `@UseRowClass`.

{% assign snippets = "package:drift_docs/snippets/custom_row_classes/default.dart.excerpt.json" | readString | json_decode %}
{% include "blocks/snippet" snippets = snippets name = "start" %}

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

{% assign snippets = "package:drift_docs/snippets/custom_row_classes/named.dart.excerpt.json" | readString | json_decode %}
{% include "blocks/snippet" snippets = snippets name = "named" %}

### Static and aynchronous factories

Starting with drift 2.0, the custom constructor set with the `constructor`
parameter on the `@UseRowClass` annotation may also refer to a static method
defined on the class to load.
That method must either return the row class or a `Future` of that type.
Unlike a named constructor or a factory, this can be useful in case the mapping
from SQL to Dart needs to be asynchronous:

```dart
class User {
  // ...

  static Future<User> load(int id, String name, DateTime birthday) async {
    // ...
  }
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

This feature is also supported for views. Simply add the `WITH ClassName` syntax
after the name of the view in the `CREATE VIEW` statement:

```sql
CREATE VIEW my_view WITH ExistingClass AS SELECT ...
```

You can make drift target named constructors too:

```sql
CREATE TABLE users(
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  birth_date DATETIME NOT NULL
) WITH User.myNamedConstructor;
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

## Existing row classes for queries {#queries}

Existing row classes may also be applied to named queries defined in a `.drift` file.
They have a similar syntax, adding the `WITH` keyword after the name of the query:

```sql
import 'my_existing_class.dart';

/*
Assuming a Dart class like the following:

class MyExistingClass {
  final String name;
  final double avgAge;

  MyExistingClass(this.name, this.avgAge);
}
*/

myQuery WITH MyExistingClass: SELECT name, AVG(age) AS avg_age FROM entries GROUP BY category;
```

Again, you can also target a named constructor:

```sql
/*
class MyExistingClass {
  final String name;
  final double avgAge;

  MyExistingClass.fromSql(this.name, this.avgAge);
}
*/

myQuery WITH MyExistingClass.fromSql: SELECT name, AVG(age) AS avg_age FROM entries GROUP BY category;
```

For your convenience, drift is using different generation strategies even for queries _without_
an existing row class. It is helpful to enumerate them because they affect the allowed type for
fields in existing types as well.

1. Nested tables: When the [`SELECT table.**` syntax]({{ 'SQL API/drift_files.md#nested-results' | pageUrl }})
   is used in a query, drift will pack columns  from `table` into a nested object instead of generating fields
   for every column.
2. Nested list results: The [`LIST()` macro]({{ 'SQL API/drift_files.md#list-subqueries' | pageUrl }})
   can be used to expose results of a subquery as a list.
3. Single-table results: When a select statement reads all columns from a table (and no additional columns),
   like in `SELECT * FROM table`, drift will use the data class of the table instead of generating a new one.
4. Single-column results: When a select statement only has a single column, but _doesn't represent a full table_,
   drift will not generate a full result class for it. Instead, the value is returned directly.
5. Other results: This is probably the most common case in practice: All result sets that don't
   fall into one of the existing categorizations are said to have a _normal_ result set.

Depending on what kind of result set your query has, you can use different fields for the existing Dart class:

1. For a nested table selected with `**`, your field needs to store a structure compatible with the result set
   the nested column points to. For `my_table.**`, that field could either be the generated row class for `MyTable`
   or a custom class as described by rule 3.
2. For nested list results, you have to use a `List<T>`. The `T` has to be compatible with the inner result
   set of the `LIST()` as described by these rules.
3. For a single-table result, you can use the table class, regardless of whether the table uses an existing table
   class or whether it is generated by drift.
   If that matches the intention of your query better, you may also choose to use a _different_ class for
   nested tables, provided that all fields of that class can be mapped to a column as described by these rules.
4. For a single-column result, you may either use that type directly or a single-field class wrapping it.
5. For normal results, each field of your result class must match the name of a column in that result set.
   The type of the column must be assignable to the field in your class, drift will also take type converters
   into account here.
     - For a `**` column in a normal result set, see rule 1.
     - For a `LIST()` column in a normal result set, see rule 2.

While these rules may seem complicated when entirely spelled out, they are designed to match the
intuitive mapping one would expect.
Consider this example:

{% assign nested_drift = "package:drift_docs/snippets/custom_row_classes/employees_sql.drift.excerpt.json" | readString | json_decode %}

{% include "blocks/snippet" name = "example" snippets = nested_drift %}

Using the rules as defined above, let's see how the `EmployeeWithStaff` class can look like:
The outermost result set has three columns: A `**` column, a simple expression column and a `LIST`
column. That means that this query falls under rule 5.
This essentially means that we get to write a class.
For the simple column that references the `name` column, we know it must be a string because the
column was defined with `TEXT`.

```dart
class EmployeeWithStaff {
  final T1 self;
  final String supervisor;
  final T3 staff;

  EmployeeWithStaff(this.self, this.supervisor, this.staff);
}
```

As `self` is a `**` column, rule 1 applies. `self` references a table, `employees`.
By rule 3, this means that `T1` can be a `Employee`, the row class for the `employees` table.
On the other hand, `staff` is a `LIST()` column and rule 2 applies here. This means that `T3` must
be a `List<Something>`.
The inner result set of the `LIST` references all columns of `employees` and nothing more, so rule
3 applies. Thus, we can either use `Employee` again, or another custom row class referencing columns
from that table.
The final class can now look like this:

```dart
class IdAndName {
  final int id;
  final String name;

  // This class can be used since id and name column are available from the list query.
  // We could have also used the `Employee` class or a record like `(int, String)`.
  IdAndName(this.id, this.name);
}

class EmployeeWithStaff {
  final Employee self;
  final String supervisor;

  // We could have also picked List<Employee> for this field
  final List<IdAndName> staff;

  EmployeeWithStaff(this.self, this.supervisor, this.staff);
}
```

In practice, the rules should be intuitive while also being flexible enough for you to
design the result classes the way you like.

If you have questions about existing result classes, or think you have found an edge-case not
properly handled, please [start a discussion](https://github.com/simolus3/drift/discussions/new) in
the drift repository, thanks!

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

