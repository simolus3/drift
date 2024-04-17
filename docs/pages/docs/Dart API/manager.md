---
data:
  title: Manager
  description: Use easier bindings for common queries.
  weight: 1

template: layouts/docs/single
---

{% assign snippets = 'package:drift_docs/snippets/dart_api/manager.dart.excerpt.json' | readString | json_decode %}

With generated code, drift allows writing SQL queries in typesafe Dart.
While this is provides lots of flexibility, it requires familiarity with SQL.
As a simpler alternative, drift 2.17 introduced a new set of APIs designed to
make common queries much easier to write.

The examples on this page use the database from the [setup]({{ '../setup.md' | pageUrl }})
instructions.

## Select

### Count and exists

### Filtering across tables

### Ordering

## Updates
We can use the manager to update rows in bulk or individual rows that meet a certain condition.

{% include "blocks/snippet" snippets = snippets name = 'manager_update' %}

We can also replace an entire row with a new one. Or even replace multiple rows at once.

{% include "blocks/snippet" snippets = snippets name = 'manager_replace' %}

## Creating rows
The manager includes a method for quickly inserting rows into a table.
We can insert a single row or multiple rows at once.

{% include "blocks/snippet" snippets = snippets name = 'manager_create' %}


## Deleting rows
We may also delete rows from a table using the manager.
Any rows that meet the specified condition will be deleted.

{% include "blocks/snippet" snippets = snippets name = 'manager_delete' %}

