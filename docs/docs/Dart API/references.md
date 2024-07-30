---

title: References
description: Define foreign keys to establish relationships between tables in your database.

---

Foreign keys establish relationships between tables, maintaining referential integrity in your database.  
Define a foreign keys using the `references` method:

{{ load_snippet('references','lib/snippets/dart_api/tables.dart.excerpt.json') }}

The first parameter to `references` is the table to reference.
The second parameter is a [symbol](https://dart.dev/guides/language/language-tour#symbols) of the column to use for the reference.
The type of the column must match the type of the column it references.

These references can be used in queries to join tables and fetch related data.

{{ load_snippet('example-references','lib/snippets/dart_api/manager.dart.excerpt.json') }}


### Reference Names

By default, Drift will name this reference after the table it references with `Refs` appended.
For instance, the reference in the [example](#references) above is named `todoItemsRefs`.

To use a custom reference name, use the `@ReferenceName(...)` annotation.


!!! example "Example"

    In the following example we are using the `@ReferenceName` annotation to name the reference `books` instead of `bookRefs`.  
    
    {{ load_snippet('reference-name','lib/snippets/dart_api/tables.dart.excerpt.json', indent=4) }}

    We are also using the `KeyAction.cascade` parameter to delete all books when a publisher is deleted.  See the [next section](#foreign-key-actions) for more information on key actions.

### Foreign Key Actions

Foreign key constraints help maintain data consistency in related tables. They're like rules that connect information in different parts of your database.

For example, imagine you have a table of users and a table of groups. Each user belongs to a group. What should happen if you delete a group that still has users in it?

This is where 'onUpdate' and 'onDelete' come in. They tell the database what to do when you change or remove connected information:

- `onDelete` decides what happens to related data when you delete something.
- `onUpdate` decides what happens when you change a value that other data depends on.

There are different options for how to handle these situations, like automatically deleting related data or preventing changes that would break connections between data.

See the [sqlite documentation](https://sqlite.org/foreignkeys.html#fk_actions) for more information on the available actions.

!!! info "Foreign Key Constraints"

    Be aware that, in sqlite3, foreign key references aren't enabled by default.  
    They need to be enabled with `PRAGMA foreign_keys = ON`.
    A suitable place to issue that pragma with drift is in a [post-migration callback](../Migrations/index.md#post-migration-callbacks).
