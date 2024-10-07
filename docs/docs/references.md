---

title: Relationship
description: Define relationships between tables.

---

## Overview

A foreign key is a column in one table that refers to the primary key in another table. It establishes a link between two tables, creating a relationship between them.

#### Example

Consider the relationship between a `User` table and a `Group` table.   
Each user belongs to a group, and each group can have multiple users.

**Group Table**

| id  | group_name |
| --- | ---------- |
| 1   | Admin      |
| 2   | User       |

**User Table**

| id  | user_name | group |
| --- | --------- | ----- |
| 1   | Alice     | 1     |
| 2   | Bob       | 2     |
| 3   | Carol     | 2     |

Here, the `group` column in the User table is a foreign key referencing `id` in the Group table.

The following sections will show how to define these relationships using Drift.

## Many-to-One Relationships

To define a reference, use the `references` method in the table schema.
This method takes 2 arguments:

- The table that the reference points to.
- The column in the other table that the reference points to.

Here's how the `User` table from the example above could be defined:
<div class="annotate">
{{ load_snippet('user_group_schema','lib/snippets/references.dart.excerpt.json') }}
</div>
1. This `@ReferenceName("users") `annotation is optional, It's used to name the reference in the generated code. If you don't provide it, one will be generated for you.
2. This `#id` syntax may look unfamiliar to you. It's a uncommonly used syntax in Dart called [Symbol literals](https://dart.dev/guides/language/language-tour#symbols).

## Constraints

By default, SQLite does not enforce foreign key constraints. 
Meaning, if you were to create a user with a group that does not exist, SQLite would allow it.

**This is not ideal for maintaining data integrity.**

To enable foreign key constraints in your database, add the custom SQL statement `PRAGMA foreign_keys = ON;` to the `beforeOpen` callback of your database's migration as follows:

{{ load_snippet('foreign_keys_on','lib/snippets/references.dart.excerpt.json') }}

For more details on common pragmas and additional database configuration options, refer to the [Database]() documentation.

#### Violating Constraints

By default, if [foreign key constraints](#foreign-key-constraints) are enabled and a foreign key constraint is violated, an exception will be thrown.

These constraints can be violated by:

- Deleting a row in the referenced table. (e.g A group is deleted, but users still reference it.)

- Updating the primary key in the referenced table. (e.g A group's ID is changed, but users still reference the old ID.)

This behavior can be customized using the `onDelete` and `onUpdate` parameters in the `references` method.

<div class="annotate" markdown>

- **`KeyAction.cascade`**: The referenced rows are deleted or updated when the referenced row is deleted or updated.
- **`KeyAction.setDefault`** & **`KeyAction.setNull`**: The referenced column is set to a default value or `null` when the referenced row is deleted or updated.
-  **`KeyAction.noAction`** (default) & **`KeyAction.restrict`**: An exception is thrown when the referenced row is deleted or updated. (1)

</div>

1. The only difference between `KeyAction.noAction` and `KeyAction.restrict` is that deferred foreign key constraints will still be enforced mid-transaction with `KeyAction.restrict`.

## Query References

When fetching data from the database, you can use the `withReferences` method to fetch references along with the main table.

{{ load_snippet('manager_references','lib/snippets/references.dart.excerpt.json') }}

#### Prefetching references

Drift provides a way to prefetch references in a single query to avoid inefficient queries. This is done by using the callback in the `withReferences` method. The referenced item will then be available in the referenced managers `prefetchedData` field.

{{ load_snippet('manager_prefetch_references','lib/snippets/references.dart.excerpt.json') }}

## Filtering and Ordering

Filters may be applied from the many side of the relationship. For example, to find todos of a specific category:

{{ load_snippet('manager_filter_forward_references','lib/snippets/references.dart.excerpt.json') }}

And from the one side of the relationship. For example, to find the category of a specific todo:

{{ load_snippet('manager_filter_back_references','lib/snippets/references.dart.excerpt.json') }}

The same is true for ordering:

{{ load_snippet('manager_order_forward_references','lib/snippets/references.dart.excerpt.json') }}

!!! info "Filtering on Reference Columns"

    **If you have [foreign key constraints enabled](#constraints), filtering on reference columns works as expected.**

    However, without foreign key constraints, there are special considerations:

    1. Filters on reference columns apply to the local column, not the referenced table.
    2. Example: `todos.filter((f) => f.category.id(1))` filters on the `category` column in `todos`, not `id` in `categories`.
    3. This doesn't verify if the referenced category actually exists.

    To ensure data integrity and expected behavior, always enable foreign key constraints.

## Many-to-Many Relationships

Drift does not support many-to-many relationships directly. Instead, you can create a junction table to represent the relationship.

For example, consider a many-to-many relationship between `Books` and `Tags` tables. A book can have multiple tags, and a tag can be associated with multiple books.

This relationship can be represented using a junction table `TagBookRelationship`:

{{ load_snippet('many_to_many_schema','lib/snippets/references.dart.excerpt.json') }}

You can now use this table to query books by tag or tags by book.

{{ load_snippet('many_to_many_usage','lib/snippets/references.dart.excerpt.json') }}


## Advanced

### Deferred Constraints

By default, foreign key constraints are checked immediately. So the following code will throw an exception:

{{ load_snippet('deferred_constraints','lib/snippets/references.dart.excerpt.json') }}

Although an author with id `f7b3b3e0...` will exist at the end of the transaction, the foreign key constraint is checked immediately after the insert, causing an exception.

To defer the constraint check until the end of the transaction, use the `initiallyDeferred` parameter in the `references` method:

{{ load_snippet('define_deferred_constraints','lib/snippets/references.dart.excerpt.json') }}

Now, the foreign key constraint will be checked at the end of the transaction, allowing the code to run without throwing an exception.