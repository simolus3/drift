---
data:
  title: "Transactions"
  weight: 4
  description: Run multiple statements atomically

template: layouts/docs/single
path: /docs/transactions/
aliases:
  - /transactions/
---

{% assign snippets = "package:drift_docs/snippets/dart_api/transactions.dart.excerpt.json" | readString | json_decode %}

Drift has support for transactions and allows multiple statements to run atomically,
so that none of their changes is visible to the main database until the transaction
is finished.
To begin a transaction, call the `transaction` method on your database or a DAO.
It takes a function as an argument that will be run transactionally. In the
following example, which deals with deleting a category, we move all todo entries
in that category back to the default category:

{% include "blocks/snippet" snippets = snippets name = "deleteCategory" %}

## ⚠️ Important things to know about transactions {#-gotchas}
There are a couple of things that should be kept in mind when working with transactions:

1. __Await all calls__: All queries inside the transaction must be `await`-ed. The transaction
  will complete when the inner method completes. Without `await`, some queries might be operating
  on the transaction after it has been closed! This can cause data loss or runtime crashes.
  Drift contains some runtime checks against this misuse and will throw an exception when a transaction
  is used after being closed.
2. __Different behavior of stream queries__: Inside a `transaction` callback, stream queries behave
differently. If you're creating streams inside a transaction, check the next section to learn how
they behave.

## Transactions and query streams
Query streams that have been created outside a transaction work nicely together with
updates made in a transaction: All changes to tables will only be reported after the
transaction completes. Updates inside a transaction don't have an immediate effect on
streams, so your data will always be consistent and there aren't any unnecessary updates.

Streams created _inside_ a `transaction` block (or in a function that was called inside
a `transaction`) block reflect changes made in a transaction immediately.
However, such streams close when the transaction completes.

This behavior is useful if you're collapsing streams inside a transaction, for instance by
calling `first` or `fold`.
However, we recommend that streams created _inside_ a transaction are not listened to
_outside_ of a transaction. While it's possible, it defeats the isolation principle
of transactions as its state is exposed through the stream.

## Nested transactions

Starting from drift version 2.0, it is possible to nest transactions on most implementations.
When calling `transaction` again inside a `transaction` block (directly or indirectly through
method invocations), a _nested transaction_ is created. Nested transactions behave as follows:

- When they start, queries issued in a nested transaction see the state of the database from
  the outer transaction immediately before the nested transaction was started.
- Writes made by a nested transaction are only visible inside the nested transaction at first.
  The outer transaction and the top-level database don't see them right away, and their stream
  queries are not updated.
- When a nested transaction completes successfully, the outer transaction sees the changes
  made by the nested transaction as an atomic write (stream queries created in the outer
  transaction are updated once).
- When a nested transaction throws an exception, it is reverted (so in that sense, it behaves
  just like other transactions).
  The outer transaction can catch this exception, after it will be in the same state before
  the nested transaction was started. If it does not catch that exception, it will bubble up
  and revert that transaction as well.

The following snippet illustrates the behavior of nested transactions:

{% include "blocks/snippet" snippets = snippets name = "nested" %}

### Supported implementations

Nested transactions require support by the database implementation you're using with drift.
All popular implementations support this feature, including:

- A `NativeDatabase` from `package:drift/native.dart`
- A `WasmDatabase` from `package:drift/wasm.dart`
- The sql.js-based `WebDatabase` from `package:drift/web.dart`
- A `SqfliteDatabase` from `package:drift_sqflite`.

Further, nested transactions are supported through remote database connections (e.g.
isolates or web workers) if the server uses a database implementation that supports them.
