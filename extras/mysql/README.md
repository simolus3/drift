Experimental support for using Moor with an MySQL server.

## Using this
For general notes on using moor, see [this guide](https://moor.simonbinder.eu/getting-started/).
To use the MySQL backend, also add this to your pubspec (you don't need to depend on
`moor_flutter`).
```yaml
dependencies:
  moor: "$latest version"
  moor_mysql:
   git:
    url: https://github.com/simolus3/moor.git
    path: extras/mysql 
```

Then, instead of using a `FlutterQueryExecutor`, use a `MySqlBackend` with the
right [`ConnectionSettings`](https://pub.dev/documentation/sqljocky5/latest/connection_settings/ConnectionSettings-class.html).
You'll need to import `package:moor_mysql/moor_mysql.dart`.

## Limitations
We're currently experimenting with other database engines - Moor was mainly designed for
sqlite and supporting advanced features of MySQL is not a priority right now.
- No migrations - you'll need to create your tables manually
- Some statements don't work
- Compiled custom queries don't work - we can only parse sqlite. Of course, runtime custom
queries with `customSelect` and `customUpdate` will work as expected.