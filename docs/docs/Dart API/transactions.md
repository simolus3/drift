---

title: Transactions
description: Run multiple statements atomically

---



Drift supports transactions, letting you group multiple database changes into one unit. This ensures all changes succeed together or none happen, helping keep your data accurate and consistent. 


### Example Schema

All the examples on this page use the following schema:

??? example "Schema"

    {{ load_snippet('schema','lib/snippets/dart_api/manager.dart.excerpt.json', indent=4) }}

### Running a transaction

To begin a transaction, call the `transaction` method on your database.
All the code inside the `transaction` block will be run atomically. If an exception is thrown, the transaction will be rolled back and none of the changes will be applied.

For example, in this function we are adding a new category with with todos.  
We want to ensure that we never have a category without any todos, so we wrap the two inserts in a transaction:

{{ load_snippet('addCategoryWithTodos','lib/snippets/dart_api/manager.dart.excerpt.json') }}

By wrapping the above code in a transaction, we ensure that either all the changes are applied or none are.

!!! warning "Await all calls"
    All queries inside the transaction must be `await`-ed.  
    Any queries that are not awaited will be executed after the transaction has completed.

    The following code could cause data loss or runtime crashes:
  
    {{ load_snippet('badTransaction','lib/snippets/dart_api/manager.dart.excerpt.json') }}

    Drift contains some runtime checks against this misuse and will throw an exception when a transaction is used after being closed.

## Transactions and Streams

Any query which is `watch`ing a table won't be updated until the transaction completes. This ensures that your data is always consistent and that you don't receive any unnecessary updates.

For example, a query which is watching the `categories` table will only be updated after the transaction completes.
  
{{ load_snippet('streamTransaction','lib/snippets/dart_api/manager.dart.excerpt.json') }}

However, any stream created _inside_ a transaction will reflect changes made in the transaction immediately.

This behavior is useful if you're collapsing streams inside a transaction, for instance by
calling `first` or `fold`.


## Nested transactions

Transactions can be nested inside one another when doing complex operations. 
This inner-transaction must be `await`-ed.

If an inner transaction fails, the outer transaction will also fail and all changes will be rolled back.
However, if you wrap the inner transaction in a try-catch block, only the inner transaction will be rolled back.

Changes made in the inner transaction are only visible to the outer transaction after the inner transaction completes successfully.

The following snippet illustrates the behavior of nested transactions:

{{ load_snippet('nested','lib/snippets/dart_api/manager.dart.excerpt.json') }}