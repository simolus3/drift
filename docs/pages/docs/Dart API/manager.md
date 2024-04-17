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

## Updates

## Creating rows

{% include "blocks/snippet" snippets = snippets name = 'create' %}

## Deleting rows

