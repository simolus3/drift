---

title: Tracing database operations
description: Using the `QueryInterceptor` API to log details about database operations.

---



Drift provides the relatively simple `logStatements` option to print the statements it
executes.
The `QueryInterceptor` API can be used to extend this logging to provide more information,
which this example will show.

{{ load_snippet('class','lib/snippets/log_interceptor.dart.excerpt.json') }}

Interceptors can be applied with the `interceptWith` extension on `QueryExecutor` and
`DatabaseConnection`:

{{ load_snippet('use','lib/snippets/log_interceptor.dart.excerpt.json') }}

The `QueryInterceptor` class is pretty powerful, as it allows you to fully control the underlying
database connection. You could also use it to retry some failing statements or to aggregate
statistics about query times to an external monitoring service.
