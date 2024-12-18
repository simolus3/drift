---
title: Stream queries
description: Watch SQL queries in drift
---

A core feature of drift is that every query can be turned into an auto-updating stream.
This works regardless of whether the query returns a single or multiple rows, or whether
the query is reading from a single table or joining multiple others.

## Basics

In drift, a runnable query is represented by the `Selectable<T>` interface, which has the following
methods:

- __`Future<List<T>> get()`__: Runs the query once, returning all rows.
- __`Future<T> getSingle()`__: Runs the query once, asserts that it yields a single row which is returned.
- __`Future<T?> getSingleOrNull()`__: Like `getSingle()`, but allows returning `null` for empty result sets.

And each of these methods has a matching `watch()` method returning a stream:

- __`Stream<List<T>> watch()`__: Watches the query, returning all rows.
- __`Stream<T> watchSingle()`__: Watches the query, asserting that a single row is reported each time the query runs.
- __`Stream<T?> watchSingleOrNull()`__: Like `watchSingle()`, but returning empty result sets as `null`.

All drift APIs for building queries return a `Selectable` that can be watched:

=== "Core query builder"

    {{ load_snippet('core','lib/snippets/dart_api/streams.dart.excerpt.json', indent=4) }}
=== "Manager"

    {{ load_snippet('manager','lib/snippets/dart_api/streams.dart.excerpt.json', indent=4) }}
=== "Custom query"

    {{ load_snippet('custom','lib/snippets/dart_api/streams.dart.excerpt.json', indent=4) }}

    1. Drift needs to know which tables are involved in a query to watch them. This is inferred automatically in most cases, but
    this information is necessary for custom queries.
=== "Compiled queries"

    When defining a `SELECT` statement in a [drift file](../sql_api/drift_files.md), drift generates
    a method in the database class returning a `Selectable`. For instance,

    ```sql
    allItemsAfter: SELECT * FROM todo_items WHERE created_at > :min;
    ```

    Will make drift generate this method:

    ```dart
    Selectable<TodoItem> allItemsAfter({required DateTime min}) {
        // ...
    }
    ```

Regardless of the method used, a stream can then be created
with `allItemsAfter(value).watch()`.
And as `Stream`s are a common building block in Dart, they can be consumed by most frameworks:

- In Flutter, you can declaratively listen on streams with a [`StreamBuilder`](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html).
- Riverpod can wrap streams with a [`StreamProvider`](https://riverpod.dev/docs/providers/stream_provider).
  This technique is also used in the [example app](https://github.com/simolus3/drift/blob/79e696719aa5d44b5edd30eb886e1fe5443a8b8f/examples/app/lib/screens/home/state.dart#L7-L12).

## Advanced uses

In addition to listening on queries, you can also listen for update events on tables directly:

{{ load_snippet('tableUpdates','lib/snippets/dart_api/streams.dart.excerpt.json') }}

Note that the entire query stream functionality is implemented in drift,
so stream updates are a heuristic that might fire more often than necessary.
It's also possible to mark a table as updated manually:

{{ load_snippet('markUpdated','lib/snippets/dart_api/streams.dart.excerpt.json') }}

## Caveats

While streams are useful to automically get updates for whatever queries you're running, it's
important to understand their functionality and limitations.
Stream queries are implemented as a heuristic in drift: For each active stream, drift tracks
which tables it's listening on (information that is available from the query builder).
Whenever an insert, an update, or a deletion is made through drift APIs, the associated
queries are rescheduled and will run again.

This means that:

1. Other uses of the database, e.g. a native SQLite client, will not trigger stream query
   updates. You can [manually inject updates](#advanced-uses) as a workaround.
2. Stream queries generally update more often than they have to, since we can't filter for
   updates on specific rows only.
   This is typically not a problem, but something to be aware of. Stream queries should typically
   return relatively few rows and not be too computationally expensive to execute.
