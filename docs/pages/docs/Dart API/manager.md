---
data:
  title: Manager
  description: Use easier bindings for common queries.
  weight: 1

template: layouts/docs/single
path: /docs/manager/
---

{% assign snippets = 'package:drift_docs/snippets/dart_api/manager.dart.excerpt.json' | readString | json_decode %}

With generated code, drift allows writing SQL queries in type-safe Dart.
While this is provides lots of flexibility, it requires familiarity with SQL.
As a simpler alternative, drift 2.18 introduced a new set of APIs designed to
make common queries much easier to write.

The examples on this page use the database from the [setup]({{ '../setup.md' | pageUrl }})
instructions.

When manager generation is enabled (default), drift will generate a manager for each table in the database.  
A collection of these managers are accessed by a getter `managers` on the database class.
Each table will have a manager generated for it unless it uses a custom row class.

## Select

The manager simplifies the process of retrieving rows from a table. Use it to read rows from the table or watch
for changes.

{% include "blocks/snippet" snippets = snippets name = 'manager_select' %}

The manager provides a really easy to use API for selecting rows from a table. These can be combined with `|` and `&`  and parenthesis to construct more complex queries. Use `.not` to negate a condition.

{% include "blocks/snippet" snippets = snippets name = 'manager_filter' %}

Every column has filters for equality, inequality and nullability.
Type specific filters for `int`, `double`, `Int64`, `DateTime` and `String` are included out of the box.

{% include "blocks/snippet" snippets = snippets name = 'manager_type_specific_filter' %}


### Referencing other tables

The manager also makes it easy to query an entities referenced fields by using the `withReferences` method.
This will return a record with the entity and a `refs` object which contains the referenced fields.

{% include "blocks/snippet" snippets = snippets name = 'manager_references' %}

The problem with the above approach is that it will issue a separate query for each row in the result set. This can be very inefficient if you have a large number of rows. If there were 1000 todos, this would issue 1000 queries to fetch the category for each todo.

{% block "blocks/alert" title="Watching with Prefetches" color="info" %}
If you are using `watch` you can use the `withPrefetches` method to prefetch references in a single query.
However changes to the referenced table will not trigger a re-query of the parent table.

{% include "blocks/snippet" snippets = snippets name = 'manager_prefetch_references_stream' %}

This is because that when single references (e.g a category has a single user) are prefetched, they are included in the same query as the parent table. Therefore, when the user table changes, the query will be re-run and the parent table will be updated. However, when multiple references are prefetched, they are included in a separate query. Therefore, changes to the referenced table will not trigger a re-query of the parent table.

{% endblock %}

#### Prefetching references

Drift provides a way to prefetch references in a single query to avoid inefficient queries. This is done by using the callback in the `withReferences` method. The referenced item will then be available in the referenced managers `prefetchedData` field.

{% include "blocks/snippet" snippets = snippets name = 'manager_prefetch_references' %}

### Filtering across tables
You can filter across references to other tables by using the generated reference filters. You can nest these as deep as you'd like and the manager will take care of adding the aliased joins behind the scenes.

{% include "blocks/snippet" snippets = snippets name = 'manager_filter_forward_references' %}

You can also filter across back references. This is useful when you have a one-to-many relationship and want to filter the parent table based on the child table. 

{% include "blocks/snippet" snippets = snippets name = 'manager_filter_back_references' %}

The code generator will name this filterset using the name of the table that is being referenced. In the above example, the filterset is named `todoItemsRefs`, because the `TodoItems` table is being referenced.
However, you can also specify a custom name for the filterset using the `@ReferenceName(...)` annotation on the foreign key. This may be necessary if you have multiple references to the same table, take the following example:

{% include "blocks/snippet" snippets = snippets name = 'user_group_tables' %}

We can now use them in a query like this:

{% include "blocks/snippet" snippets = snippets name = 'manager_filter_custom_back_references' %}

In this example, had we not specified a custom name for the reference, the code generator would have named both filtersets `userRefs` for both references to the `User` table. This would have caused a conflict. By specifying a custom name, we can avoid this issue.


#### Name Clashes
Drift auto-generates filters and orderings based on the names of your tables and fields. However, many times, there will be duplicates.  
When this happens, you will see a warning message from the generator.  
To fix this issue, use the `@ReferenceName()` annotation to specify what we should name the filter/orderings.


### Ordering

You can also order the results of a query using the `orderBy` method. The syntax is similar to the `filter` method.
Use the `&` to combine multiple orderings. Orderings are applied in the order they are added.
You can also use ordering across multiple tables just like with filters.

{% include "blocks/snippet" snippets = snippets name = 'manager_ordering' %}


### Count and exists
The manager makes it easy to check if a row exists or to count the number of rows that match a certain condition.

{% include "blocks/snippet" snippets = snippets name = 'manager_count' %}

{% include "blocks/snippet" snippets = snippets name = 'manager_exists' %}


## Updates
We can use the manager to update rows in bulk or individual rows that meet a certain condition.

{% include "blocks/snippet" snippets = snippets name = 'manager_update' %}

We can also replace an entire row with a new one. Or even replace multiple rows at once.

{% include "blocks/snippet" snippets = snippets name = 'manager_replace' %}

## Creating rows
The manager includes a method for quickly inserting rows into a table.
We can insert a single row or multiple rows at once.

{% include "blocks/snippet" snippets = snippets name = 'manager_create' %}


## Deleting rows
We may also delete rows from a table using the manager.
Any rows that meet the specified condition will be deleted.

{% include "blocks/snippet" snippets = snippets name = 'manager_delete' %}

<!-- 
This documentation should added once the internal manager APIs are more stable

## Extensions
The manager provides a set of filters and orderings out of the box for common types, however you can
extend them to add new filters and orderings.

#### Custom Column Filters
If you want to add new filters for individual columns types, you can extend the `ColumnFilter<T>` class.

{% include "blocks/snippet" snippets = snippets name = 'manager_filter_extensions' %}

#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

{% include "blocks/snippet" snippets = snippets name = 'manager_custom_filter' %}

#### Custom Column Orderings
You can create new ordering methods for individual columns types by extending the `ColumnOrdering<T>` class.
Use the `ComposableOrdering` class to create complex orderings.

{% include "blocks/snippet" snippets = snippets name = 'manager_ordering_extensions' %}

#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

{% include "blocks/snippet" snippets = snippets name = 'manager_custom_filter' %} -->
