---

title: Tables
description: Everything there is to know about defining SQL tables in Dart.

---

Tables are the cornerstone of relational databases, defining the structure and relationships of your data. In Drift, you create tables by extending the `Table` class, allowing you to define your schema in a type-safe manner.

## Table Definition

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

## Relationships

Drift supports Many-to-One relationships between tables. See the [References](./references.md) page for more information.

## Table Name

By default, drift uses the `snake_case` name of the Dart getter in the database.   
Fo example a table named `EnabledCategories` would be generated as `enabled_categories`.

To override the table name, simply override the `tableName` getter.

{{ load_snippet('custom-table-name','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The updated class would be generated as `#!sql CREATE TABLE categories (parent INTEGER NOT NULL)`.

## Indexes

[Indexes](https://sqlite.org/lang_createindex.html) are like book indexes: they help find information quickly.

Define an index on a column by adding the `@TableIndex` annotation to the table class.
Each index needs to have its own unique name. Typically, the name of the table is part of the
index' name to ensure unique names.

These can be used multiple times to define multiple indexes on a table.

{{ load_snippet('index','lib/snippets/dart_api/tables.dart.excerpt.json') }}

Now if we were to filter or sort based on `age` or `name`, the database would use the index to speed up the query.

!!! note "Automatic Indexing"

    There are some cases where you don't need to define an index explicitly.  
    Columns which are:

    - Primary keys
    - Have a unique constraint
    - Referenced by a foreign key

    are automatically indexed and shoul not have an additional index defined.

???+ tip "When to use indexes"

    Use indexes on columns that meet the following criteria:

    1. Belong to tables with a large number of rows
    2. Are frequently used for filtering or sorting operations
    3. Are not Primary Keys or part of a unique constraint
    4. Are not referenced by a foreign key

### Multi-Column indexes

While these two syntaxes look very similar, they have different meanings:

1. **Multiple Indexes on a Table**

    {{ load_snippet('mulit-single-col-index','lib/snippets/dart_api/tables.dart.excerpt.json', indent=4) }}
    This creates two separate indexes, one for each column. 
    Queries that filter on each column independently can use the index.
    However, queries that filter on both columns can't use the indexes as efficiently.

2. **Multi-Column Index**

    {{ load_snippet('multi-col-index','lib/snippets/dart_api/tables.dart.excerpt.json', indent=4) }}

    This creates a single index that covers both columns. Queries that use both or the first column (name) can use the index. However, queries that only filter on the second column (age) can't use the index.

This topic is quite complex, and out of scope for this documentation. See [here](https://www.sqlitetutorial.net/sqlite-index/) for more information.

