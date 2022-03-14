# Drift core

`drift_core` is a package defining common classes to compose SQL queries in Dart.

It has the following goals:

- Designed with support for different SQL dialects in mind.
- Easy to extend and customize.
- Lightweight and unopinionated with few dependencies.

Essentially, it is drift minus:

- Query streams
- Mapping queries to results
- Transaction management
- Batches
- Provided database implementations
- ...

Eventually, the idea is for `drift` to depend (and export parts of) `drift_core`.
Until then, the query builder is duplicated in the two packages.
Drift will continue to focus on client-side databases with features like query
streams, but `drift_core` is ready to support a wide range of SQL dialects and
server-side usages.
