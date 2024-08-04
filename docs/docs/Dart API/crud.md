---

title: CRUD
description: CRUD operations with the Drift API.

---


This page describes how to perform CRUD operations with your generated Drift Client. CRUD is an acronym that stands for:

- **Create** - Insert new records into the database.
- **Read** - Fetch records from the database.
- **Update** - Modify existing records in the database.
- **Delete** - Remove records from the database.

## Example Schema

All the examples on this page use the following schema:

??? example "Schema"

    {{ load_snippet('schema','lib/snippets/dart_api/manager.dart.excerpt.json', indent=4) }}

## Create

### Create a single record

The following example demonstrates how to create a single record:

{{ load_snippet('manager_create_single','lib/snippets/dart_api/manager.dart.excerpt.json') }}

There are several methods for creating records:

<div class="annotate" markdown>

- `create` - Create a new record, returning the primary key of the new record.
- `createAndReturn` - Create a new record and return the full record.
- `createReturningOrNull` - Create a new record and return the full record, or `null` if a records wasn't created. (1) 

</div>

1.  `createReturningOrNull` will still throw an exception if a record wasn't created due to a constraint violation. 
    `createReturningOrNull` will only return `null` if the `mode` was set to `InsertMode.insertOrIgnore` , or if the upsert clause has a `filter` which doesn't match any rows.

Each of these methods have a `mode` parameter that can be used to specify how to handle conflicts.

!!! example "Example"

    {{ load_snippet('manager_create_mode','lib/snippets/dart_api/manager.dart.excerpt.json', indent=4) }}

    Normally, adding a record with a duplicate title would throw an exception. (See the above [example schema](#example-schema)) 
    However, by setting the `mode` to `InsertMode.insertOrReplace`, the existing record would be replaced with the new record.

    See the [InsertMode](https://pub.dev/documentation/drift/latest/drift/InsertMode.html) documentation for more information on the different modes available.

### Create multiple records

When creating multiple records at once, use the `bulkCreate` method.  
This will insert all the records in a single transaction, which is more efficient than inserting each record individually.

{{ load_snippet('manager_create_multiple','lib/snippets/dart_api/manager.dart.excerpt.json') }}

## Read

### Get all records

Records can be read/watched using the `get` and `watch` methods provided by the Manager API.

{{ load_snippet('retrieve_all','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Get a single record

The following example demonstrates how to retrieve a single record:

{{ load_snippet('retrieve_single','lib/snippets/dart_api/manager.dart.excerpt.json') }}

Drift provides helper methods for retrieving singletons:

- `getSingle` - Retrieve a single record, throwing an exception if more than one record is found or if no records are found.
- `getSingleOrNull` - Retrieve a single record, only throwing an exception if more than one record is found.
- `watchSingle` - Same as `getSingle`, but returns a stream of the record.
- `watchSingleOrNull` - Same as `getSingleOrNull`, but returns a stream of the record.

### Get the first record

The following example demonstrates how to retrieve the first record:

{{ load_snippet('retrieve_first','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Pagination

Retrieving all the records from a table with a large number of records can be inefficient.  
Use the `limit` and `offset` methods to paginate the results.

{{ load_snippet('pagination','lib/snippets/dart_api/manager.dart.excerpt.json') }}

The `limit` parameter restricts the number of records returned, while `offset` skips a certain number of records before returning the rest.

!!! warning "Limit and Offset"

    `offset` has no effect if used without `limit`. In the following example, no records will be skipped:

    {{ load_snippet('pagination-bad','lib/snippets/dart_api/manager.dart.excerpt.json', indent=4) }}
    

### Distinct

When you perform complex queries that involve multiple tables, it is possible to get duplicate records in the result set.

To avoid this, set `distinct: true`. This will remove duplicate records from the result set.

???+ note "Isn't this a bug?"

    The presence of duplicate records in the result set is not an issue specific to drift. It is a common behavior in SQL queries.

### Filter and Sort

Creating complex queries is made easier by using the `filter` and `orderBy` methods.

{{ load_snippet('filter-and-sort-summary','lib/snippets/dart_api/manager.dart.excerpt.json') }}

See the [Filter and Sort](filter-and-sort.md) documentation for more information on filtering records.

### Referenced Queries

Drift makes it easy to retrieve referenced fields from other tables using the `withReferences` method.

{{ load_snippet('with-references-summary','lib/snippets/dart_api/manager.dart.excerpt.json') }}

See the [Read References](referenced-queries.md) documentation for more information on referencing other tables.

## Update

Drift provides multiple methods for updating records:

- `update` - Update a record, writing the changes to the database. Returns an integer representing the number of records updated.
- `replace` - Replace a record, completely overwriting the record in the database. Returns `true` if any modifications were made.
- `bulkReplace` - Replace multiple records at once. Does not return anything.

{{ load_snippet('manager_update','lib/snippets/dart_api/manager.dart.excerpt.json') }}

See the [Filter and Sort](filter-and-sort.md) documentation to filter which records are updated. 

## Delete

Use the `delete` method to delete records from the database.

{{ load_snippet('manager_delete','lib/snippets/dart_api/manager.dart.excerpt.json') }}

See the [Filter and Sort](filter-and-sort.md) documentation to filter which records are deleted.

## Additional Methods

### Count

Use the `count` method to count the number of records in a table.

{{ load_snippet('manager_count','lib/snippets/dart_api/manager.dart.excerpt.json') }}

!!! note "Distinct"
    When counting records, `distinct` is set to `true` by default.
    This differs from the `get` and `watch` methods, where `distinct` is set to `false` by default.  
    See the [Distinct](#distinct) section for more information.

### Exists

To check if any records exist that match a certain condition, use the `exists` method.

{{ load_snippet('manager_exists','lib/snippets/dart_api/manager.dart.excerpt.json') }}

## Performance Considerations

Massive database operations can slow down an application's main thread, potentially causing performance issues. This happens because tasks like query building and data processing often occur on the same thread that handles user interface updates.

Consider using `computeWithDatabase` to offload these tasks to a background isolate. This method is available on the `DriftDatabase` class.

{{ load_snippet('computeWithDatabase','lib/snippets/dart_api/manager.dart.excerpt.json') }}


