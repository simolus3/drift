# drift_flutter

`drift_flutter` is a utility package for [drift](https://drift.simonbinder.eu/)
databases in Flutter apps.
The core `drift` package is Dart-only, meaning that it can't depend on Flutter
or any Flutter-only packages.
This complicates the setup, as all Flutter apps using drift have to introduce
Flutter-specific code to setup drift databases.
This package solves that problem by providing drift extensions for Flutter,
making it easy to open databases.

## Features

This package provides a single method: `driftDatabase`, which returns a drift
database implementation suitable for the current platform. It has a single
required parameter, the name of the database to use.

To use this package, use the method to open your database class:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

@DriftDatabase(...)
final class MyAppDatabase extends _$MyAppDatabase {
  // Keeping a custom constructor is useful for unit tests which may want to
  // open an in-memory database only.
  MyAppDatabase(super.e);

  MyAppDatabase.defaults(): super(driftDatabase(name: 'app_db'));
}
```

### Web support

Running sqlite3 on the web requires additional sources which currently have to
be downloaded into the `web/` folder of your Flutter application.
These are the compiled `sqlite3.wasm` module and a `drift_worker.js` worker
used to share databases across tabs if possible.
Obtaining these files is [described here](https://drift.simonbinder.eu/web/#prerequisites).

### Sharing databases between isolates

In some setups, for instance when using `WorkManager`, you may have two
independent isolates running your app and a background service. These may have
to share a database without blocking each other. This package can internally
use the `IsolateNameServer` to spawn a dedicated database isolates shared
between other application isolates. To enable this feature, set
`shareAcrossIsolates` to `true` in `DriftNativeOptions`:

```dart
  MyAppDatabase.defaults(): super(
    driftDatabase(
      name: 'app_db',
      native: DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    )
  );
```

When the option is enabled, `drift_flutter` will create a dedicated database
isolate that starts when the first `driftDatabase()` call connects and stops
when all attached databases have been closed (note that you need to explicitly
`close()` the databases to stop the server, the respective isolates shutting
down is not enough).

## Behavior

On native platforms (Android, iOS, macOS, Linux and Windows), `driftDatabase` uses
`getApplicationDocumentsDirectory()` from `package:path_provider` as the folder to
store databases.
Inside that folder, a `$name.sqlite` file is used for the database.
To use a custom path, the `DriftNativeOptions.databasePath` parameter can be used.

On the web, [drift's web support](https://drift.simonbinder.eu/web/) is used to open
the database.
