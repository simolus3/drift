---

title: Tracing database operations
description: Using the `QueryInterceptor` API to log details about database operations.

---

Drift provides the relatively simple `logStatements` option to print the statements it
executes.
The `QueryInterceptor` API can be used to extend this logging to provide more information,
which this example will show.

<Snippet href="/lib/src/snippets/log_interceptor.dart" name="class" />

Interceptors can be applied with the `interceptWith` extension on `QueryExecutor` and
`DatabaseConnection`:

<Snippet href="/lib/src/snippets/log_interceptor.dart" name="use" />

If you only want to apply an interceptor on a certain block instead of on the whole database,
that's possible too:

<Snippet href="/lib/src/snippets/log_interceptor.dart" name="runWithInterceptor" />

The `QueryInterceptor` class is pretty powerful, as it allows you to fully control the underlying
database connection. You could also use it to retry some failing statements or to aggregate
statistics about query times to an external monitoring service.
