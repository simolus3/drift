Tools that make using [drift](https://drift.simonbinder.eu/) easier in apps using [Riverpod](https://riverpod.dev/)
for state management.

## Features

This package provides a simple provider helper to create drift databases as a
provider:

```dart
import 'package:drift_riverpod/drift_riverpod.dart';
import 'package:drift_flutter/drift_flutter.dart';

final database = DriftProvider((ref) => Database(driftDatabase(...)));
```

This package also provides a code-generator that allows turning SQL queries into
well-typed providers. To define them, annotate a top-level variable with `@queryProvider`.
The initializer of that variable must call a non-existing method on the database to provide
the SQL statement to run, like this:

```dart
@queryProvider
final allUsers = database.$allUsers('SELECT * FROM users');
```

Here:

1. `database` must be a `ProviderListenable` providing a drift database or DAO.
2. `$allUsers` can be any method name.
3. The argument must be a string literal. It will be analyzed by `drift_riverpod` at build time
   to validate the statement and generate a mapping to Dart.

After running `build_runner` the usual way, `drift_riverpod` will have turned `allUsers`
into a working provider:

```dart
final AsyncValue<List<User>> users = ref.watch(allUsers);
```

### Advanced usage

For query providers that return a single row only, use the full `@QueryProvider()` annotation
and pass `singleRow: true`:

```dart
@QueryProvider(singleRow: true)
final countUsers = database.$countUsers('SELECT COUNT(*) FROM users;');
```

## Additional information

An overview of this package is also available under the Drift documentation website.