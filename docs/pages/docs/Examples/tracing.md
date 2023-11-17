---
data:
  title: "Tracing database operations"
  description: Using the `QueryInterceptor` API to log details about database operations.
template: layouts/docs/single
---

{% assign snippets = 'package:drift_docs/snippets/log_interceptor.dart.excerpt.json' | readString | json_decode %}

Drift provides the relatively simple `logStatements` option to print the statements it
executes.
The `QueryInterceptor` API can be used to extend this logging to provide more information,
which this example will show.

{% include "blocks/snippet" snippets=snippets name="class" %}

Interceptors can be applied with the `interceptWith` extension on `QueryExecutor` and
`DatabaseConnection`:

{% include "blocks/snippet" snippets=snippets name="use" %}

The `QueryInterceptor` class is pretty powerful, as it allows you to fully control the underlying
database connection. You could also use it to retry some failing statements or to aggregate
statistics about query times to an external monitoring service.
