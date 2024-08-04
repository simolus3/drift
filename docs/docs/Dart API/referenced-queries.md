---

title: References
description: Querying referenced fields in a single query.

---

Drift makes it easy to retrieve referenced fields from other tables using the `withReferences` method.

{{ load_snippet('with-references-summary','lib/snippets/dart_api/manager.dart.excerpt.json') }}

This can be used together with filters and orderings to create complex queries that span multiple tables.   

When `withReferences` is applied to a query, the items returned will have a 2nd property that contains a prebuilt query to fetch the referenced fields.

{{ load_snippet('with-references-explained','lib/snippets/dart_api/manager.dart.excerpt.json') }}

!!! warning "Warning"
    The above code will issue a separate query for each row in the result set. This can be very inefficient if you have a large number of rows. See the section on prefetching for a more efficient way to fetch referenced fields.

### Prefetching

To avoid issuing a separate query for each row in the result set, you can use the `withReferences` with a prefetch callback. This will fetch all referenced fields in a single query.

{{ load_snippet('manager_prefetch_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

In the above example we are prefetching the `todos` field for each `Category`. This will issue a single query to fetch all todos for all categories.