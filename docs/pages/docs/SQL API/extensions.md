---
data:
  title: "Supported sqlite extensions"
  weight: 10
  description: Information on json1 and fts5 support in drift files
template: layouts/docs/single

aliases:
 - docs/using-sql/extensions/
---

When analyzing `.drift` files, the generator can consider sqlite3 extensions
that might be present.
The generator can't know about the sqlite3 library your database is talking to
though, so it makes a pessimistic assumption of using an old sqlite3 version
without any enabled extensions by default.
When using a package like `sqlite3_flutter_libs`, you get the latest sqlite3
version with the json1 and fts5 extensions enabled. You can inform the generator
about this by using [build options]({{ "../Generation options/index.md" | pageUrl }}).

## json1

To enable the json1 extension in drift files and compiled queries, modify your
[build options]({{ "../Generation options/index.md" | pageUrl }}) to include
`json1` in the `sqlite_module` section.

The sqlite extension doesn't require any special tables and works on all text columns. In drift
files and compiled queries, all `json` functions are available after enabling the extension.

Since the json extension is optional, enabling it in Dart requires a special import,
`package:drift/extensions/json1.dart`. An example that uses json functions in Dart is shown below:
```dart
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';

class Contacts extends Table {
    IntColumn get id => integer().autoIncrement()();
    TextColumn get data => text()();
}

@DriftDatabase(tables: [Contacts])
class Database extends _$Database {
  // constructor and schemaVersion omitted for brevity

  Future<List<Contacts>> findContactsWithNumber(String number) {
    return (select(contacts)
      ..where((row) {
        // assume the phone number is stored in a json key in the `data` column
        final phoneNumber = row.data.jsonExtract<String, StringType>('phone_number');
        return phoneNumber.equals(number);
      })
    ).get();
  }
}
```

You can learn more about the json1 extension on [sqlite.org](https://www.sqlite.org/json1.html).

## fts5

The fts5 extension provides full-text search capabilities in sqlite tables.
To enable the fts5 extension in drift files and compiled queries, modify the
[build options]({{ "../Generation options/index.md" | pageUrl }}) to include
`fts5` in the `sqlite_module` section.

Just like you'd expect when using sqlite, you can create a fts5 table in a drift file
by using a `CREATE VIRTUAL TABLE` statement.
```sql
CREATE VIRTUAL TABLE email USING fts5(sender, title, body);
```

Queries on fts5 tables work like expected:
```sql
emailsWithFts5: SELECT * FROM email WHERE email MATCH 'fts5' ORDER BY rank;
```

The `bm25`, `highlight` and `snippet` functions from fts5 can also be used in custom queries.

It's not possible to declare fts5 tables, or queries on fts5 tables, in Dart.
You can learn more about the fts5 extension on [sqlite.org](https://www.sqlite.org/fts5.html).
