---

title: Queries
description: Use easier bindings for common queries.

---

## Example Schema

The examples on this page use the following database schema:

{{ load_snippet('before_generation','lib/snippets/setup/database.dart.excerpt.json' ,title="database.dart") }}

See the [tables](./tables.md) documentation for more information on how to define tables.

# Queries

Drift offers three main approaches for querying your database:

- **Manager API**: The Manager API provides a simpler, more intuitive interface for common operations
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

=== "Manager API"

    Drift generates a manager for each table in your database. They are accessible through the `managers` property on the database class. Use the `filter()`, `orderBy()`, `withReferences()` and `withFields()` methods to create queries.

    **Example:**
    {{ load_snippet('manager_example','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    Use the `select()`, `update()`, `delete()` and `into()` methods on the database class to create queries.

    **Example:**
    {{ load_snippet('core_example','lib/snippets/dart_api/manager.dart.excerpt.json') }}


Read on to learn more about writing queries.

## Reads

=== "Manager API"


    {{ load_snippet('manager_select','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    {{ load_snippet('core_select','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Watching

You can watch for changes to the database using the `watch()` method. This will return a stream of results that will emit a new value whenever the underlying data changes.

=== "Manager API"

    {{ load_snippet('manager_watch','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    {{ load_snippet('core_watch','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Pagination

When dealing with a large number of results, consider using pagination to avoid performance issues.

=== "Manager API"

    {{ load_snippet('manager_limit','lib/snippets/dart_api/manager.dart.excerpt.json') }}

=== "Core API"

    {{ load_snippet('core_limit','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Filters

Apply filters to your queries to narrow down the results.


=== "Manager API"

    Use the filterset provided in the `filter()` callback to build filters.

    <div class="annotate" markdown>
    {{ load_snippet('manager_filter','lib/snippets/dart_api/manager.dart.excerpt.json',indent=4) }}
    </div>

    1. Use the `not()` method to negate a filter.   
    2. Use the `&` operator to combine filters with an AND operator.
    3. Use the `|` operator to combine filters with an OR operator.

=== "Core API"

    Use the schema provided in the `where()` callback to build boolean expressions.
    See the [Expressions](./expressions.md) documentation for more information.

    <div class="annotate" markdown>
    {{ load_snippet('core_filter','lib/snippets/dart_api/manager.dart.excerpt.json',indent=4) }}
    </div>

    1. Use the `not()` method to negate a filter.   
    2. Use the `&` operator to combine filters with an AND operator.
    3. Use the `|` operator to combine filters with an OR operator.



### Ordering

Order the results of a query using the `orderBy()` method.

=== "Manager API"

    <div class="annotate" markdown>
    {{ load_snippet('manager_ordering','lib/snippets/dart_api/manager.dart.excerpt.json',indent=4) }}
    </div>

    1. Use the `&` operator to chain multiple orderings.

=== "Core API"

    Use the `orderBy()` method to order by multiple columns. The list of orderings are applied from top to bottom.

    {{ load_snippet('core_ordering','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### References

=== "Manager API"

    #### Reads

    Use the `withReferences()` method to load references in a query. Use `prefetch` to load the references in a single query.

    <div class="annotate" markdown>
    {{ load_snippet('manager_references_read','lib/snippets/dart_api/manager.dart.excerpt.json') }}
    </div>

    1. Using `prefetch(category: true)` creates a query which will fetch the `category` for each `todo` in a single query. This is more efficient than fetching each `category` individually.

    !!! note ":rotating_light: Avoid Lazy Loading"

        When using the Manager API, prefer prefetching references over loading them lazily. Lazy loading will execute a separate query for each row in the result set, significantly impacting performance.

        However, Lazy loading is useful when you only need the reference after performing some operation on the result set.

        For example, in a Flutter app, you might only want to load all the categories when the user navigates to the category screen. When the user taps on a category, you can then load all the todos associated with that category.

        In this instance, prefetching all the categories would be wasteful, as we may never use them.

    #### Filter & Order

    {{ load_snippet('manager_filter_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}


=== "Core API"

    !!! tip "Advanced Topic"

        SQL is a powerful language for querying databases. Most of Drifts Core API closely mirrors SQL itself.
        If you find the following section difficult to understand, consider learning more about [joins](https://www.w3schools.com/sql/sql_join.asp/) in SQL before reading this section.

    #### Joins

    The first step to use a reference in a query is to join the table.
    Use the `join()` method with the joins you want to apply. Drift supports `innerJoin()`, `leftOuterJoin()` and `crossJoin()`

    {{ load_snippet('joins','lib/snippets/dart_api/manager.dart.excerpt.json') }}

    #### Read

    Once a join has been applied, queries will return a `TypedResult` instead of a data class (e.g. `TodoItem`).
    Use the `readTable()` & `readTableOrNull()` methods to read the data class from the `TypedResult`.

    <div class="annotate" markdown>
    {{ load_snippet('core_read_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}
    </div>

    1. The schema does not enforce that every `todo` has a `category`. Use `readTableOrNull()` to handle this case.
    2. This will execute a separate query for each row in the result set. This should only be used for one off tasks.

    #### Filter & Order

    You can use references in filters and orderings once the table has been joined.

    <div class="annotate" markdown>
    {{ load_snippet('core_filter_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}
    </div>

    3. In joins, `useColumns: false` tells drift to not add columns of the joined table to the result set. This is useful here, since we only join the tables so that we can refer to them in the where clause.

    #### Aliases

    If a table has more than one foreign key to the same table, use an alias to differentiate between them.

    {{ load_snippet('core_filter_references_alias','lib/snippets/dart_api/manager.dart.excerpt.json') }}

    #### Aggregates

    Use the `addColumns()` & `groupBy()` methods to add aggregate columns to the query.
    Drift has built-in support for `count()`, `sum()`, `avg()`, `min()`, `max()` and `groupConcat()`.

    {{ load_snippet('core_aggregates','lib/snippets/dart_api/manager.dart.excerpt.json') }}

    #### Subqueries

    Drift supports using subqueries to construct a join. This example demonstrates this by using a subquery to only join a subset of the `todoCategory` table.

    {{ load_snippet('core_subquery','lib/snippets/dart_api/manager.dart.excerpt.json') }}


    

    



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


#### Custom Table Filters
You can also create custom filters that operate on multiple columns by extending generated filtersets.

{{ load_snippet('manager_custom_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }} -->
