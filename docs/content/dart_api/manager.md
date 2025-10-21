---

title: Manager
description: Use easier bindings for common queries.

---

Drift provides two ways to write queries in Dart: A [query builder](select.md) that
closely mirrors SQL in Dart, and a new generated manager interface, described on this page.
The manager interfaces are designed to make the most common queries much easier to write.
In particular, they should be helpful if you're coming from another persistence library to drift or
don't have much SQL experience.

The examples on this page use a database schema similar to the one from the [setup](../setup.md) instructions:

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="tables" />

## Select

When manager generation is enabled (which it is by default), drift will generate a manager
for each table in the database.
A collection of these managers are accessed by a getter `managers` on the database class.
Each table will have a manager generated for it unless it uses a custom row class.

The manager simplifies the process of retrieving rows from a table. Use it to read rows from the table or watch
for changes.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_select" />

The manager provides a really easy to use API for selecting rows from a table. These can be combined with `|` and `&`  and parenthesis to construct more complex queries. Use `.not` to negate a condition.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_filter" />

Every column has filters for equality, inequality and nullability.
Type specific filters for `int`, `double`, `Int64`, `DateTime` and `String` are included out of the box.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_type_specific_filter" />

### Referencing other tables

The manager also makes it easy to query an entity's referenced fields by using the `withReferences` method.
This will return a record with the entity and a `refs` object which contains the referenced fields.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_references" />

The problem with the above approach is that it will issue a separate query for each row in the result set. This can be very inefficient if you have a large number of rows.
If there were 1000 todos, this would issue 1000 queries to fetch the category for each todo.

!!! note "Filter on foreign keys"

    When filtering on a reference column, drift will apply the filter to the column itself instead of joining the referenced table.
    For example, `todos.filter((f) => f.category.id(1))` will filter on the `category` column on the `todos` table, instead of joining the two tables and filtering on the `id` column of the `categories` table.

    <h4>How does this affect me?</h4>

    If you have foreign keys contraints enabled (`PRAGMA foreign_keys = ON`) this won't affect you. The database will enfore that the `id` column on the `categories` table is the same as the `category` column on the `todos` table.

    If you don't have foreign key constraints enabled, you should be aware that the above query will not check that the category with `id` 1 exists. It will only check that the `category` column on the `todos` table is 1.


#### Prefetching references

Drift provides a way to prefetch references in a single query to avoid inefficient queries. This is done by using the callback in the `withReferences` method. The referenced item will then be available in the referenced managers `prefetchedData` field.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_prefetch_references" />

### Filtering across tables
You can filter across references to other tables by using the generated reference filters. You can nest these as deep as you'd like and the manager will take care of adding the aliased joins behind the scenes.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_filter_forward_references" />

You can also filter across back references. This is useful when you have a one-to-many relationship and want to filter the parent table based on the child table.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_filter_back_references" />

The code generator will name this filterset using the name of the table that is being referenced. In the above example, the filterset is named `todoItemsRefs`, because the `TodoItems` table is being referenced.
However, you can also specify a custom name for the filterset using the `@ReferenceName(...)` annotation on the foreign key. This may be necessary if you have multiple references to the same table, take the following example:

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="user_group_tables" />

We can now use them in a query like this:

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_filter_custom_back_references" />

In this example, had we not specified a custom name for the reference, the code generator would have named both filtersets `userRefs` for both references to the `User` table. This would have caused a conflict. By specifying a custom name, we can avoid this issue.


#### Name Clashes
Drift auto-generates filters and orderings based on the names of your tables and fields. However, many times, there will be duplicates.
When this happens, you will see a warning message from the generator.
To fix this issue, use the `@ReferenceName()` annotation to specify what we should name the filter/orderings.


### Ordering

You can also order the results of a query using the `orderBy` method. The syntax is similar to the `filter` method.
Use the `&` to combine multiple orderings. Orderings are applied in the order they are added.
You can also use ordering across multiple tables just like with filters.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_ordering" />

When including nullable columns in `orderBy`, you might want to control whether `NULL` values are
placed at the start or end of the results. This is possible with the `nulls` parameter on `asc()` and
`desc()`.
For instance, you could write `o.title.asc(nulls: NullsOrder.first)` to request that todo items without
a title appear before those that have one.

### Count and exists
The manager makes it easy to check if a row exists or to count the number of rows that match a certain condition.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_count" />

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_exists" />


## Updates
We can use the manager to update rows in bulk or individual rows that meet a certain condition.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_update" />

We can also replace an entire row with a new one. Or even replace multiple rows at once.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_replace" />

## Creating rows
The manager includes a method for quickly inserting rows into a table.
We can insert a single row or multiple rows at once.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_create" />

## Deleting rows
We may also delete rows from a table using the manager.
Any rows that meet the specified condition will be deleted.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_delete" />

## Computed Fields

Manager queries are great when you need to select entire rows from a database table along with their related data. However, there are situations where you might want to perform more complex operations directly within the database for better efficiency.

Drift offers strong support for writing SQL expressions. These expressions can be used to filter data, sort results, and perform various calculations directly within your SQL queries. This means you can leverage the full power of SQL to handle complex logic right in the database, making your queries more efficient and your code cleaner.

If you want to learn more about how to write these SQL expressions, please refer to the [expression](expressions.md) documentation.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_annotations" />

You can write expressions which reference other columns in the same table or even other tables.
The joins will be created automatically by the manager.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="referenced_annotations" />

You can also use [aggregate](./expressions.md#aggregate-functions-like-count-and-sum) functions too.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="aggregated_annotations" />

<!--
This documentation should added once the internal manager APIs are more stable

## Extensions
The manager provides a set of filters and orderings out of the box for common types, however you can
extend them to add new filters and orderings.

#### Custom Column Filters
If you want to add new filters for individual columns types, you can extend the `ColumnFilter<T>` class.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_filter_extensions" />

#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_custom_filter" />

#### Custom Column Orderings
You can create new ordering methods for individual columns types by extending the `ColumnOrdering<T>` class.
Use the `ComposableOrdering` class to create complex orderings.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_ordering_extensions" />

#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

<Snippet href="/lib/src/snippets/dart_api/manager.dart" name="manager_custom_filter" /> -->
