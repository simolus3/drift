---

title: Queries
description: Create, read, update, and delete data in your database.

---

Drift makes it easy to write type-safe queries, ensuring that your database interactions are reliable and error-free. Additionally, Drift can watch for changes in your data, allowing your application to react in real-time to updates, inserts, and deletions. 

Drift offers 3 main ways to interact with your database:

1. **Manager API**: A simple, high-level API for interacting with your database. The Manager API is the easiest way to get started with Drift, and is perfect for simple queries and updates.
2. **Core API**: A low-level API that allows you to write custom queries and interact with your database in a more fine-grained way.
3. **Type-Safe SQL**: If you prefer to write raw SQL queries, Drift provides a type-safe way to do so. This allows you to write SQL queries that are checked at compile-time, ensuring that your queries are always correct.

This page will cover the Manager API. For information on the Core API and Type-Safe SQL, see the [Core API](/docs/core) and [Type-Safe SQL](/docs/sql) pages.


<h2>Manager API</h2>

Drift generates a manager for each table in your database. This manager provides a simple API for creating, reading, updating, and deleting data in your database.
It can be accessed via the `managers` property on the `Database` object.

{{ load_snippet('superhero_query','lib/snippets/schema.dart.excerpt.json') }}

If you don't plan to use the Manager API, you can disable it by setting `generate_manager: false` in your `build.yaml` file.

<div class="result" markdown>

=== "`build.yaml`"
    ```yaml
    targets:
      $default:
        builders:
          drift_dev:
            options:
              generate_manager: true # enabled by default
              # generate_manager: false
    ```


</div>


## Query Builder

The Manager API provides a query builder that allows you to build complex queries using a fluent API.
By chaining methods together, you can filter, sort, and paginate your data with ease.

Once you have built your query, you can execute it using the [`get`](#get-all-records), [`watch`](#get-all-records), [`update`](#update), [`delete`](#delete), [`count`](#count), or [`exists`](#exists) methods.

### Filter

Use the `filter` method to filter records based on a condition.

In Dart, logical operators `&&` (AND) and `||` (OR) are commonly used within parentheses to combine multiple conditions for logical expressions.
```dart
if (condition1 && condition2) {
  // do something
}
```
Similarly, in Drift, an additional set of operators, `&` (AND) and `|` (OR), are available to combine conditions.

{{ load_snippet('filter','lib/snippets/queries.dart.excerpt.json') }}

To negate a condition, use the `not` method.

{{ load_snippet('filter-not','lib/snippets/queries.dart.excerpt.json') }}

### Ordering

Use the `orderBy` method to sort records based on a column.
The `&` operator is used to combine multiple sorting conditions.

{{ load_snippet('order','lib/snippets/queries.dart.excerpt.json') }}

### Limit

Performing queries that return a large number of records can be inefficient.
Use the `limit` and `offset` methods to paginate the results.

{{ load_snippet('pagination','lib/snippets/queries.dart.excerpt.json') }}

The `limit` parameter restricts the number of records returned, while `offset` skips a certain number of records before returning the rest.

!!! warning "Limit and Offset"

    `offset` has no effect if used without `limit`. In the following example, no records will be skipped:

    {{ load_snippet('pagination-bad','lib/snippets/queries.dart.excerpt.json', indent=4) }}

## Read

### Get all records

Records can be read/watched using the `get` and `watch` methods provided by the Manager API.

{{ load_snippet('retrieve_all','lib/snippets/queries.dart.excerpt.json') }}

### Get a single record

The following example demonstrates how to retrieve a single record:

{{ load_snippet('retrieve_single','lib/snippets/queries.dart.excerpt.json') }}

Drift provides helper methods for retrieving singletons:

- `getSingle` - Retrieve a single record, throwing an exception if exactly one record is not found.
- `getSingleOrNull` - Retrieve a single record, throwing an exception if more than one record is found.
- `watchSingle` - Same as `getSingle`, but returns a stream of the record.
- `watchSingleOrNull` - Same as `getSingleOrNull`, but returns a stream of the record.

### Distinct

When you perform complex queries that involve multiple tables, it is possible that duplicate records will be returned.

To avoid this, set `distinct: true`. This will remove duplicates.

???+ note "Isn't this a bug?"

    The presence of duplicate records in the result set is not an issue specific to drift. It is a common behavior in SQL queries.

### Referenced Queries

Drift makes it easy to retrieve referenced fields from other tables using the `withReferences` method.

{{ load_snippet('with-references-summary','lib/snippets/queries.dart.excerpt.json') }}

See the [Read References](referenced-queries.md) documentation for more information on referencing other tables.

## Update

Drift provides multiple methods for updating records:

- `update` - Update a record, writing the changes to the database. Returns an integer representing the number of records updated.
- `replace` - Replace a record, completely overwriting the record in the database. Returns `true` if any modifications were made.
- `bulkReplace` - Replace multiple records at once. Does not return anything.

{{ load_snippet('manager_update','lib/snippets/queries.dart.excerpt.json') }}


## Delete

Use the `delete` method to delete records from the database.

{{ load_snippet('manager_delete','lib/snippets/queries.dart.excerpt.json') }}


## Count

Use the `count` method to count the number of records in a table.

{{ load_snippet('manager_count','lib/snippets/queries.dart.excerpt.json') }}

!!! note "Distinct"
    When counting records, `distinct` is set to `true` by default.
    This differs from the `get` and `watch` methods, where `distinct` is set to `false` by default.  
    See the [Distinct](#distinct) section for more information.

## Exists

To check if any records exist that match a certain condition, use the `exists` method.

{{ load_snippet('manager_exists','lib/snippets/queries.dart.excerpt.json') }}

## Create

To create a new record, use the `create` method on the manager. This method will return the id of the new record.(1)
{ .annotate }

1. If the primary key of the table is an auto-incrementing integer, the ID will be the value of the primary key.   
    If the primary key is anything else, Drift adds a column named `rowid` to the table and returns the value of that column.


{{ load_snippet('manager_simple_create_single','lib/snippets/queries.dart.excerpt.json') }}

If you want to get the full record back, use the `createReturning` method instead.

{{ load_snippet('manager_returning_create_single','lib/snippets/queries.dart.excerpt.json') }}


### Insert Modes

By default, Drift will throw an exception if a record violates a constraint(1). However, you can specify how to handle conflicts by using the `mode` parameter of the `create` method.
{ .annotate }

1. A constraint can be a [unique constraint](./schema.md#unique-columns), a [check constraint](./schema.md#custom-checks), or a [foreign key constraint](./relations.md#constraint).

Available modes include:
<div class="annotate" markdown>
- **`InsertMode.insert`** - (*default*) Throw an exception if the record violates a constraint.
- **`InsertMode.replace`** - Replace the existing record with the new one if a unique constraint is violated.
- **`InsertMode.insertOrIgnore`** - Ignore the new record if it violates a constraint. (1)

</div>

1. Do not use `InsertMode.insertOrIgnore` with `createReturning`. Use `createReturningOrNull` instead.

The following example demonstrates how to use the `mode` parameter to handle conflicts.

{{ load_snippet('manager_create_mode','lib/snippets/queries.dart.excerpt.json') }}

### Bulk Create

When creating multiple records at once, use the `bulkCreate` method.  
This will insert all the records in a single transaction, which is more efficient than inserting each record individually.

{{ load_snippet('manager_create_multiple','lib/snippets/queries.dart.excerpt.json') }}

### Update or Create (Upsert)

You can use the `create` method to perform an upsert operation. An upsert combines insert and update operations, allowing you to create a new record or update an existing one if a conflict occurs.

Note that this is a lower-level operation and is part of the Core API. For more details, refer to the [Core API](/docs/core) page.


## Performance Considerations

Database operations on a very large dataset can be time-consuming and may block the main thread, causing your application to become unresponsive.

Consider using `computeWithDatabase` to offload these tasks to a background isolate. This method is available on the `DriftDatabase` class.

{{ load_snippet('computeWithDatabase','lib/snippets/queries.dart.excerpt.json') }}