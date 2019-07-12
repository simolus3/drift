---
layout: feature
title: Transactions
nav_order: 3
since: 1.1
permalink: /transactions
---

# Transactions
Moor has support for transactions and allows multiple queries to run atomically.
To begin a transaction, call the `transaction` method on your database or a DAO.
It takes a function as an argument that will be run on the transaction. In the
following example, which deals with deleting a category, we move all todo entries
in that category back to the default category:
```dart
Future deleteCategory(Category category) {
  return transaction((t) async {
    // first, move the affected todo entries back to the default category
    await t.customUpdate(
      'UPDATE todos SET category = NULL WHERE category = ?',
      updates: {todos},
      variables: [Variable.withInt(category.id)],
    );

    // then, delete the category
    await t.delete(categories).delete(category);
  });
}
```

## ⚠️ Gotchas
There are a couple of things that should be kept in mind when working with transactions:
1. __Await all calls__: All queries inside the transaction must be `await`-ed. The transaction
  will complete when the inner method completes. Without `await`, some queries might be operating
  on the transaction after it has been closed!
2. __No select streams in transactions__: Inside a `transaction` callback, select statements can't
be `.watch()`ed. The reasons behind this is that it's unclear how a stream should behave when a
transaction completes. Should the stream complete as well? Update to data changes made outside of the
transaction? Both seem inconsistent, so moor forbids this.

## Transactions and query streams
Query streams that have been created outside a transaction work nicely together with
updates made in a transaction: All changes to tables will only be reported after the
transaction completes. Updates inside a transaction don't have an immediate effect on
streams, so your data will always be consistent.

However, as mentioned above, note that streams can't be created inside a `transaction` block.