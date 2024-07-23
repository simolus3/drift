---
data:
  title: Remote sqld & Turso
  description: Use drift with sqld database servers.
  weight: 100
template: layouts/docs/single
---

[libSQL](https://turso.tech/libsql) is a SQLite fork which supports hosting
databases with a SQLite-compatible format and dialect on servers.
Drift can connect to these databases with the [`drift_hrana`](https://pub.dev/packages/drift_hrana)
package, named after the [Hrana protocol](https://github.com/tursodatabase/libsql/blob/main/docs/HRANA_3_SPEC.md)
used to connect to such a server.

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
