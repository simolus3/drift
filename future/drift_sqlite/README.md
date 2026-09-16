This package adds SQLite support for [drift](https://pub.dev/packages/drift), a
reactive persistence library for Flutter and Dart.

## Getting started

> [!TIP]
> For Flutter apps, consider using the [drift_flutter](https://pub.dev/packages/drift_flutter) package.
> It is based on `drift_sqlite` and adds defaults to make the cross-platform setup easier.

Begin by [setting up a drift database](https://drift.simonbinder.eu/setup/). Add
a dependency on `drift_sqlite` to use it to open database connections:

```dart
import 'package:drift/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';

void main() {
  final db = ExampleDatabase(
    // TODO: Platform-specific connection setup.
  );
}

@DriftDatabase(tables: [Notes])
final class ExampleDatabase extends _$ExampleDatabase {
  ExampleDatabase(super.implementation);
  // ...
}
```

On native platforms, use `sqliteConnectionPool` to open a high-performance pool of SQLite
connections:

```dart
// For native platforms
final db = ExampleDatabase(sqliteConnectionPool(
  file: File('test.db')
));
```

On the web, download `sqlite3.wasm` and `drift_worker.js` from a [drift release](https://github.com/simolus3/drift/releases)
into the `web/` directory of your app. Then, use this snippet to open databases:

```dart
// For the web
final db = ExampleDatabase(DriftConnection(
  dialect: SqliteDialect.new,
  openConnection: () async {
    final web = WebSqlite.open(
      wasmModule: '/sqlite3.wasm',
      workers: .defaultWorkers('/drift_worker.js'),
      controller: WasmDatabase.driftDatabaseController(),
    );
    final db = await web.connectToRecommended('my_database_name');
    return WasmDatabase.wrapDatabase(rawDb);
  }
));
```

## Sponsors

Drift is proudly Sponsored by [Stream 💙](https://getstream.io/chat/sdk/flutter/?utm_source=Moor&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=Moor_July2022_FlutterChatSDK_klmh22) and [PowerSync](https://powersync.com/?utm_source=drift&utm_campaign=drift_sponsorship).

<p align="center">
<table>
    <tbody>
        <tr>
            <td align="center">
                <a href="https://getstream.io/chat/sdk/flutter/?utm_source=Moor&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=Moor_July2022_FlutterChatSDK_klmh22" target="_blank"><img width="250px" src="https://stream-blog.s3.amazonaws.com/blog/wp-content/uploads/fc148f0fc75d02841d017bb36e14e388/Stream-logo-with-background-.png"/></a><br/><span><a href="https://getstream.io/chat/sdk/flutter/?utm_source=Moor&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=Moor_July2022_FlutterChatSDK_klmh22" target="_blank">Try the Flutter Chat Tutorial &nbsp💬</a></span>
            </td>
            <td align="center">
                <a href="https://powersync.com/?utm_source=drift&utm_campaign=drift_sponsorship" target="_blank"><img width="250px" src="https://powersync.com/images/brand/powersync-logo-light-bg.png"/></a><br/>
                <span><a href="https://docs.powersync.com/integrations/supabase/guide?&utm_campaign=drift_sponsorship">Try PowerSync with Supabase</a></span>
            </td>
        </tr>
    </tbody>
</table>
</p>