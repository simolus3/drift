---
data:
  title: "Transactions"
  weight: 70
  description: Run multiple queries atomically

template: layouts/docs/single
aliases:
  - /transactions/ 
---

Moor has support for transactions and allows multiple queries to run atomically,
so that none of their changes is visible to the main database until the transaction
is finished.
To begin a transaction, call the `transaction` method on your database or a DAO.
It takes a function as an argument that will be run transactionally. In the
following example, which deals with deleting a category, we move all todo entries
in that category back to the default category:

```dart
Future deleteCategory(Category category) {
  return transaction(() async {
    // first, move the affected todo entries back to the default category
    await customUpdate(
      'UPDATE todos SET category = NULL WHERE category = ?',
      updates: {todos},
      variables: [Variable.withInt(category.id)],
    );

    // then, delete the category
    await delete(categories).delete(category);
  });
}
```

## ⚠️ Gotchas
There are a couple of things that should be kept in mind when working with transactions:

1. __Await all calls__: All queries inside the transaction must be `await`-ed. The transaction
  will complete when the inner method completes. Without `await`, some queries might be operating
  on the transaction after it has been closed! This can cause data loss or runtime crashes.
2. __Different behavior of stream queries__: Inside a `transaction` callback, stream queries behave
differently. If you're creating streams inside a transaction, check the next section to learn how
they behave.

## Transactions and query streams
Query streams that have been created outside a transaction work nicely together with
updates made in a transaction: All changes to tables will only be reported after the
transaction completes. Updates inside a transaction don't have an immediate effect on
streams, so your data will always be consistent and there aren't any unnecessary updates.

With streams created _inside_ a `transaction` block (or a nested call in there), it's
a different story. Notably, they

- reflect on changes made in the transaction immediately
- complete when the transaction completes

This behavior is useful if you're collapsing streams inside a transaction, for instance by
calling `first` or `fold`.
However, we recommend that streams created _inside_ a transaction are not listened to
_outside_ of a transaction. While it's possible, it defeats the isolation principle
of transactions as its state is exposed through the stream.
