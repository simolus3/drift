---

title: Queries
description: Use easier bindings for common queries.

---

Drift offers three main approaches for querying your database:

- **Manages API**: The Manager API provides a simpler, more intuitive interface for common operations
- **Core API**: The Core API provides a more flexible and powerful interface for complex queries
- **Raw SQL**: For those comfortable with SQL, you can write raw SQL queries directly. The SQL is parsed and validated at compile time.

This page will cover the Manager API and the Core API. For more information on raw SQL queries, see the [Raw SQL](./raw_sql.md) page.

??? tip "Disable Manager API"
    If you don't want to use the Manager API, you can disable it by setting `generate_manager` to `false` in the `drift` section of your `build.yaml` file. This will save you some build time and reduce the size of your generated code.
    
    ```yaml title="build.yaml"
    targets:
      $default:
        builders:
          drift_dev:
            options:
              generate_manager: false
    ```

### Example schema

The examples on this page use the following database schema:

{{ load_snippet('before_generation','lib/snippets/setup/database.dart.excerpt.json') }}


## Read

=== "Manager API"

    
    To select all rows from a table, just call the `get()`/`watch()` method on the table manager. This will return a list of all rows in the table.

    {{ load_snippet('manager_select','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    Write `SELECT` queries using the `select` method on the database class. This method returns a query object which can be used to retrieve rows from the database.

    Any query can be run once with `get()` or be turned into an auto-updating stream using `watch()`.

    {{ load_snippet('core_select','lib/snippets/dart_api/manager.dart.excerpt.json') }}


### Limit and Offset

You can limit the amount of results returned by calling `limit` on queries. The method accepts
the amount of rows to return and an optional offset.

=== "Manager API"

    {{ load_snippet('manager_limit','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    {{ load_snippet('core_limit','lib/snippets/dart_api/manager.dart.excerpt.json') }}



### Filtering

#### Simple filters

Drift generates prebuilt filters for each column in your table. These filters can be used to filter rows based on the value of a column.

=== "Manager API"

    You can apply filters to a query by calling `filter()`. The filter method takes a function that should return a filter on the given table.

    {{ load_snippet('manager_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    You can apply filters to a query by calling `where()`. The `where` method takes a function that should map the given table to an `Expression` of boolean. For more details on expressions, see the [expression](./expressions.md) docs.

    {{ load_snippet('core_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}

#### Complex filters

- Use the `&` and `|` operators to combine multiple filters.
- Use `()` to group filters.
- Use `.not` to negate a condition.


=== "Manager API"

    {{ load_snippet('manager_complex_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    {{ load_snippet('core_complex_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}



### Referencing other tables

The manager also makes it easy to query an entities referenced fields by using the `withReferences` method.
This will return a record with the entity and a `refs` object which contains the referenced fields.

{{ load_snippet('manager_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

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

{{ load_snippet('manager_prefetch_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Filtering across tables
You can filter across references to other tables by using the generated reference filters. You can nest these as deep as you'd like and the manager will take care of adding the aliased joins behind the scenes.

{{ load_snippet('manager_filter_forward_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

You can also filter across back references. This is useful when you have a one-to-many relationship and want to filter the parent table based on the child table. 

{{ load_snippet('manager_filter_back_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

The code generator will name this filterset using the name of the table that is being referenced. In the above example, the filterset is named `todoItemsRefs`, because the `TodoItems` table is being referenced.
However, you can also specify a custom name for the filterset using the `@ReferenceName(...)` annotation on the foreign key. This may be necessary if you have multiple references to the same table, take the following example:

{{ load_snippet('user_group_tables','lib/snippets/dart_api/manager.dart.excerpt.json') }}

We can now use them in a query like this:

{{ load_snippet('manager_filter_custom_back_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

In this example, had we not specified a custom name for the reference, the code generator would have named both filtersets `userRefs` for both references to the `User` table. This would have caused a conflict. By specifying a custom name, we can avoid this issue.


#### Name Clashes
Drift auto-generates filters and orderings based on the names of your tables and fields. However, many times, there will be duplicates.  
When this happens, you will see a warning message from the generator.  
To fix this issue, use the `@ReferenceName()` annotation to specify what we should name the filter/orderings.


### Ordering

You can also order the results of a query using the `orderBy` method. The syntax is similar to the `filter` method.
Use the `&` to combine multiple orderings. Orderings are applied in the order they are added.
You can also use ordering across multiple tables just like with filters.

{{ load_snippet('manager_ordering','lib/snippets/dart_api/manager.dart.excerpt.json') }}


### Count and exists
The manager makes it easy to check if a row exists or to count the number of rows that match a certain condition.

{{ load_snippet('manager_count','lib/snippets/dart_api/manager.dart.excerpt.json') }}

{{ load_snippet('manager_exists','lib/snippets/dart_api/manager.dart.excerpt.json') }}


## Updates
We can use the manager to update rows in bulk or individual rows that meet a certain condition.

{{ load_snippet('manager_update','lib/snippets/dart_api/manager.dart.excerpt.json') }}

We can also replace an entire row with a new one. Or even replace multiple rows at once.

{{ load_snippet('manager_replace','lib/snippets/dart_api/manager.dart.excerpt.json') }}

## Creating rows
The manager includes a method for quickly inserting rows into a table.
We can insert a single row or multiple rows at once.

{{ load_snippet('manager_create','lib/snippets/dart_api/manager.dart.excerpt.json') }}


## Deleting rows
We may also delete rows from a table using the manager.
Any rows that meet the specified condition will be deleted.

{{ load_snippet('manager_delete','lib/snippets/dart_api/manager.dart.excerpt.json') }}



## Computed Fields

Manager queries are great when you need to select entire rows from a database table along with their related data. However, there are situations where you might want to perform more complex operations directly within the database for better efficiency. 

Drift offers strong support for writing SQL expressions. These expressions can be used to filter data, sort results, and perform various calculations directly within your SQL queries. This means you can leverage the full power of SQL to handle complex logic right in the database, making your queries more efficient and your code cleaner.

If you want to learn more about how to write these SQL expressions, please refer to the [expression](expressions.md) documentation.

{{ load_snippet('manager_annotations','lib/snippets/dart_api/manager.dart.excerpt.json') }}

You can write expressions which reference other columns in the same table or even other tables.
The joins will be created automatically by the manager.

{{ load_snippet('referenced_annotations','lib/snippets/dart_api/manager.dart.excerpt.json') }}

You can also use [aggregate](./expressions.md#aggregate-functions-like-count-and-sum) functions too.

{{ load_snippet('aggregated_annotations','lib/snippets/dart_api/manager.dart.excerpt.json') }}

<!-- 
This documentation should added once the internal manager APIs are more stable

## Extensions
The manager provides a set of filters and orderings out of the box for common types, however you can
extend them to add new filters and orderings.

#### Custom Column Filters
If you want to add new filters for individual columns types, you can extend the `ColumnFilter<T>` class.

{{ load_snippet('manager_filter_extensions','lib/snippets/dart_api/manager.dart.excerpt.json') }}

#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

{{ load_snippet('manager_custom_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}

#### Custom Column Orderings
You can create new ordering methods for individual columns types by extending the `ColumnOrdering<T>` class.
Use the `ComposableOrdering` class to create complex orderings.

{{ load_snippet('manager_ordering_extensions','lib/snippets/dart_api/manager.dart.excerpt.json') }}

#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

{{ load_snippet('manager_custom_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }} -->
