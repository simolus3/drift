---

title: Remote sqld & Turso
description: Use drift with sqld database servers.

---

[libSQL](https://turso.tech/libsql) is a SQLite fork which supports hosting
databases with a SQLite-compatible format and dialect on servers.
libSQL also offers synchronization mechanisms to open a central database locally
and then upload local changes.

With the `drift_libsql` and `drift_hrana` packages, two solutions integrating drift
with libSQL and libSQL servers exist.
`drift_libsql` offers full synchronization capabilities with a local copy, while `drift_hrana`
connects to libSQL servers (such those offered by [Turso](https://turso.tech/)).

## drift_libsql

The libSQL library can connect to libSQL servers while also supporting a local copy of the database
that is kept in-sync with the server.
Thanks to the `libsql_dart` and [drift_libsql](https://pub.dev/packages/drift_libsql) packages written
by [Andika Tanuwijaya](https://github.com/dikatok), this functionality is also available in drift databases.

```dart
import 'package:drift/drift.dart';
import 'package:drift_libsql/drift_libsql.dart';

@DriftDatabase(...)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final database = AppDatabase(DriftLibsqlDatabase(
    "${dir.path}/replica.db",
    syncUrl: 'hrana url',
    authToken: 'your-token',
    readYourWrites: true,
    syncIntervalSeconds: 3,
  ));
}
```

## drift_hrana

Drift can connect to hosted libSQL servers with the the [`drift_hrana`](https://pub.dev/packages/drift_hrana)
package, named after the [Hrana protocol](https://github.com/tursodatabase/libsql/blob/main/docs/HRANA_3_SPEC.md)
used by libSQL.
This runs _all_ queries against the server, similarly to how one might connect to a Postgres
or a MariaDB server. No local caching or synchronization is taking place.

Once you have a host to connect to, use `HranaDatabase` as a constructor argument
to your database class:

```dart
import 'package:drift/drift.dart';
import 'package:drift_hrana/drift_hrana.dart';

@DriftDatabase(...)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final database = AppDatabase(HranaDatabase(
    Uri.parse('ws://localhost:8080/'),
    jwtToken: null,
  ));
}
```

This will make drift connect to the server and issue database calls over websockets.
Note that streamed queries will not work across different clients connecting to the
same database like this, as sqld has no support for that at the moment.

`drift_hrana` is not part of the core Drift project and instead maintained in
[this repository](https://github.com/simolus3/hrana.dart). If you have ideas for
additional features, or if you're running into problems with `drift_hrana`, please
file issues in that repository.
Just like with the core drift package, contributions are always welcome!