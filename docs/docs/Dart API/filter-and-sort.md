---

title: Filter and Sort
description: Easily filter and sort records using the Manager API.

---



## Filtering

When retrieving, updating, or deleting records, you may want to filter which records should be affected.  
Drift provides a way to filter records using the `filter` method on the manager.

Every column has filters for equality, inequality, and nullability.  

{{ load_snippet('manager_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Negating Conditions

If you want to negate a condition, you can use the `.not` property.  
In the example above `f.content.not.isNull()` will only return records where the `content`  is not `null`.

### Type Specific Filters

Additionally, type-specific filters for `int`, `double`, `Int64`, `DateTime`, and `String` are included out of the box.
More complex filters can be expressed using the `|` and `&` operators and parenthesis.

{{ load_snippet('manager_type_specific_filter','lib/snippets/dart_api/manager.dart.excerpt.json') }}

!!! note "Are we missing something?"
    If you have an idea for a new filter, please [open an issue](https://github.com/simolus3/drift/issues/new?template=feature_request.md)

### Multiple Filters

Using the `filter` method twice will combine the filters using the `AND` operator.

{{ load_snippet('manager_filter_multiple','lib/snippets/dart_api/manager.dart.excerpt.json') }}

### Filtering Across Tables

Filters can be applied to referenced fields as well.
Drift will automatically add the necessary joins to the query to filter across tables.

{{ load_snippet('manager_filter_forward_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}

This can be done in the reverse as well, so you can filter the parent table based on the child table.

{{ load_snippet('manager_filter_back_references','lib/snippets/dart_api/manager.dart.excerpt.json') }}


## Sorting

The `orderBy` method can be used to sort the result set.
Use the `&` operator to combine multiple sort conditions. The order of the conditions are applied from left to right.

{{ load_snippet('manager_ordering','lib/snippets/dart_api/manager.dart.excerpt.json') }}


### Multiple Sort Conditions

You can combine multiple sort conditions using the `&` operator or by calling `orderBy` multiple times.

{{ load_snippet('manager_ordering_multiple','lib/snippets/dart_api/manager.dart.excerpt.json') }}


### Sorting Across Tables

Just like with filters, you can also sort across tables.

{{ load_snippet('manager_ordering_relations','lib/snippets/dart_api/manager.dart.excerpt.json') }}

## Usage

Once filters and ordering are applied, any action that is called on manager will use the filtered and sorted data.

{{ load_snippet('filter-and-sort-usage','lib/snippets/dart_api/manager.dart.excerpt.json') }}

## Reverse Filter and Sort Names

Drift auto-generates filters and orderings based on the names of your tables and fields. 
However, for the reverse references, we generate them based on the name of the table that is being referenced.

In the above [example](#filtering-across-tables), the name of the filterset is `todoItemsRefs` because the `TodoItems` table is being referenced.

However if there are multiple references to the same table, the code generator will create 2 fields named `userRefs` for both references to the `User` table. This would cause a conflict.

To avoid this issue, you can specify a custom name for the filterset using the `@ReferenceName(...)` annotation on the foreign key.

See the [Reference Names](./references.md#reference-names) documentation for more information on how to use this annotation.
