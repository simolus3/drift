---

title: Tables
description: Everything there is to know about defining SQL tables in Dart.

---

Tables are the cornerstone of relational databases, defining the structure and relationships of your data. In Drift, you create tables by extending the `Table` class, allowing you to define your schema in a type-safe manner.

## Basic Table Definition

To define a table, create a class that extends `Table`. Each field in your table is represented by a getter method returning a specific column type:

{{ load_snippet('table','lib/snippets/setup/database.dart.excerpt.json') }}



!!! note "Naming conventions"
    
    Use plural names for tables (e.g., `Users`, `Categories`) to ensure generated data classes have singular names (e.g., `User`, `Category`). To override this behavior, see the [Dataclass](./dataclass.md) page.


## Columns

Columns are the building blocks of your tables. Drift supports a wide range of column types to match SQL data types:

- `IntColumn`: For integer values
- `TextColumn`: For text or string values
- `BoolColumn`: For boolean values
- `DateTimeColumn`: For date and time values
- `RealColumn`: For floating-point numbers
- `BlobColumn`: For binary large objects

Each column type comes with its own set of constraints and modifiers.   
For a detailed explanation of column definitions and their options, refer to the [Columns](./columns.md) documentation.

## Primary Keys

Primary keys uniquely identify each record in a table.  
By default, Drift will recognize an `IntColumn` with `autoIncrement()` as the primary key.

However, you can define your own primary key by overriding the `primaryKey` getter.

The following example defines a UUID as the primary key:

{{ load_snippet('primary-key','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Multiple columns can also be combined to form a composite primary key. 

!!! note "Primary Key Syntax"

    The primary key must essentially be constant so that the generator can recognize it. That means:

    - it must be defined with the `=>` syntax, function bodies aren't supported
    - it must return a set literal without collection elements like `if`, `for` or spread operators


## References

Foreign keys establish relationships between tables, maintaining referential integrity in your database.  
In Drift, you can define foreign keys using the `references` method:

{{ load_snippet('references','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The first parameter to `references` is the table to reference.
The second parameter is a [symbol](https://dart.dev/guides/language/language-tour#symbols) of the column to use for the reference.
The type of the column must match the type of the column it references.

!!! info "Foreign Key Constraints"

    Be aware that, in sqlite3, foreign key references aren't enabled by default.  
    They need to be enabled with `PRAGMA foreign_keys = ON`.
    A suitable place to issue that pragma with drift is in a [post-migration callback](../Migrations/index.md#post-migration-callbacks).

### Foreign Key Actions

Foreign key constraints help maintain data consistency in related tables. They're like rules that connect information in different parts of your database.

For example, imagine you have a table of users and a table of groups. Each user belongs to a group. What should happen if you delete a group that still has users in it?

This is where 'onUpdate' and 'onDelete' come in. They tell the database what to do when you change or remove connected information:

- 'onDelete' decides what happens to related data when you delete something.
- 'onUpdate' decides what happens when you change a value that other data depends on.

There are different options for how to handle these situations, like automatically deleting related data or preventing changes that would break connections between data.

See the [sqlite documentation](https://sqlite.org/foreignkeys.html#fk_actions) for more information on the available actions.

### Reference Names

By default, Drift will name this reference after the table it references with `Refs` appended.
For instance, the reference in the [example](#references) above would be named `todoItemsRefs`.

To use a custom reference name, use the `@ReferenceName(...)` annotation.


!!! example "Example"

    In the following example we are using the `@ReferenceName` annotation to name the reference `books` instead of `bookRefs`.
    We are also using the `KeyAction.cascade` parameter to delete all books when a publisher is deleted.

    {{ load_snippet('reference-name','lib/snippets/dart_api/tables.dart.excerpt.json', indent=4) }}

## Table Name

By default, drift uses the `snake_case` name of the Dart getter in the database.   
Fo example a table named `EnabledCategories` would be generated as `enabled_categories`.

To override the table name, simply override the `tableName` getter.

{{ load_snippet('custom-table-name','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The updated class would be generated as `#!sql CREATE TABLE categories (parent INTEGER NOT NULL)`.

## Indexes

[SQL Indexes](https://sqlite.org/lang_createindex.html) are like book indexes: they help find information quickly.  
Without them, you'd have to scan the whole database for each search, which is slow. Indexes make reads much faster, but slightly slow down adding new data.

!!! tip "When to use indexes"

    Any column that is filtered or sorted on frequently should have an index.  
    Fields likes `age`, `name`, `email`, `created_at`, `updated_at`, etc. are good candidates for indexing.

Use the `@TableIndex` annotation to define an index on a table.  
Each index needs to have its own unique name. Typically, the name of the table is part of the
index' name to ensure unique names.  
These can be used multiple times to define multiple indexes on a table.


{{ load_snippet('index','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Primary keys are automatically indexed, so you don't need to add an index for them.

!!! note "Multi-Column indexes"

    While these two syntaxes look very similar, they have different meanings:

    1. **Multiple Indexes on a Table**

        {{ load_snippet('mulit-single-col-index','lib/snippets/dart_api/tables.dart.excerpt.json', indent=8) }}
        This creates two separate indexes, one for each column. 
        Queries that filter on each column independently can use the index.
        However, queries that filter on both columns can't use the index.

    2. **Multi-Column Index**

        {{ load_snippet('multi-col-index','lib/snippets/dart_api/tables.dart.excerpt.json', indent=8) }}

        This creates a single index that covers both columns. Queries that use both or the first column (name) can use the index. However, queries that only filter on the second column (age) can't use the index.

    This topic is quite complex, and out of scope for this documentation. See [here](https://www.sqlitetutorial.net/sqlite-index/) for more information.

