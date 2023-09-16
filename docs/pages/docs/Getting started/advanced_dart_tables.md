---
data:
  title: "Dart tables"
  description: "Further information on defining tables in Dart. This page describes advanced features like constraints, nullability, references and views"
  weight: 150
path: /old-tables
template: layouts/docs/single
---

{% block "blocks/pageinfo" %}
__Prefer sql?__ If you prefer, you can also declare tables via `CREATE TABLE` statements.
Drift's sql analyzer will generate matching Dart code. [Details]({{ "starting_with_sql.md" | pageUrl }}).
{% endblock %}

{% assign snippets = 'package:drift_docs/snippets/tables/advanced.dart.excerpt.json' | readString | json_decode %}

As shown in the [getting started guide]({{ "index.md" | pageUrl }}), sql tables can be written in Dart:
```dart
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}
```

In this article, we'll cover some advanced features of this syntax.

## Primary keys

If your table has an `IntColumn` with an `autoIncrement()` constraint, drift recognizes that as the default
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


## Views

It is also possible to define [SQL views](https://www.sqlite.org/lang_createview.html)
as Dart classes.
To do so, write an abstract class extending `View`. This example declares a view reading
the amount of todo-items added to a category in the schema from [the example]({{ 'index.md' | pageUrl }}):

{% include "blocks/snippet" snippets = snippets name = 'view' %}

Inside a Dart view, use

- abstract getters to declare tables that you'll read from (e.g. `TodosTable get todos`).
- `Expression` getters to add columns: (e.g. `itemCount => todos.id.count()`).
- the overridden `as` method to define the select statement backing the view.
  The columns referenced in `select` may refer to two kinds of columns:
   - Columns defined on the view itself (like `itemCount` in the example above).
   - Columns defined on referenced tables (like `categories.description` in the example).
     For these references, advanced drift features like [type converters]({{ '../Advanced Features/type_converters.md' | pageUrl }})
     used in the column's definition from the table are also applied to the view's column.

   Both kind of columns will be added to the data class for the view when selected.

Finally, a view needs to be added to a database or accessor by including it in the
`views` parameter:

```dart
@DriftDatabase(tables: [Todos, Categories], views: [CategoryTodoCount])
class MyDatabase extends _$MyDatabase {
```

### Nullability of columns in a view

For a Dart-defined views, expressions defined as an `Expression` getter are
_always_ nullable. This behavior matches `TypedResult.read`, the method used to
read results from a complex select statement with custom columns.

Columns that reference another table's column are nullable if the referenced
column is nullable, or if the selected table does not come from an inner join
(because the whole table could be `null` in that case).

Considering the view from the example above,

- the `itemCount` column is nullable because it is defined as a complex
  `Expression`
- the `description` column, referencing `categories.description`, is non-nullable.
  This is because it references `categories`, the primary table of the view's
  select statement.
