---
data:
  title: "Importing and exporting databases"
  description: Using drift with an existing database
template: layouts/docs/single
---

You can use drift with a pre-propulated database that you ship with your app.
This page also describes how to export the underlying sqlite3 database used
by drift into a file.

## Using an existing database

You can use a `LazyDatabase` wrapper to run an asynchronous computation before drift
opens a database.
This is a good place to check if the target database file exists, and, if it doesnt,
create one.
This example shows how to do that from assets.

### Including the database

First, create the sqlite3 database you want to ship with your app.
You can create a database with the [sqlite3 CLI tool](https://sqlite.org/cli.html)
on your development machine.
Of course, you can also create the database programmatically by using a library
like [sqlite3](https://pub.dev/packages/sqlite3) (or even drift itself).

To ship that database to users, you can include it as a [flutter asset](https://flutter.dev/docs/development/ui/assets-and-images).
Simply include it in your pubspec:

```yaml
flutter:
  assets:
    - assets/my_database.db
```

### Extracting the database

To initialize the database before using drift, you need to extract the asset from your
app onto the device.
In drift, you can use a [LazyDatabase](https://pub.dev/documentation/drift/latest/drift/LazyDatabase-class.html)
to perform that work just before your drift database is opened:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));

    if (!await file.exists()) {
        // Extract the pre-populated database file from assets
        final blob = await rootBundle.load('assets/my_database.db');
        final buffer = blob.buffer;
        await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }

    return NativeDatabase.createInBackground(file);
  });
}
```

Finally, use that method to open your database:

```dart
@DriftDatabase(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  // ...
```

## Exporting a databasee

To export a sqlite3 database into a file, you can use the `VACUUM INTO` statement.
Inside your database class, this could look like the following:

```dart
Future<void> exportInto(File file) async {
  // Make sure the directory of the target file exists
  await file.parent.create(recursive: true);

  // Override an existing backup, sqlite expects the target file to be empty
  if (file.existsSync()) {
    file.deleteSync();
  }

  await customStatement('VACUUM INTO ?', [file.path]);
}
```

You can now export this file containing the database of your app with another
package like `flutter_share` or other backup approaches.

To import a database file into your app's database at runtime, you can use the
following approach:

1. use the `sqlite3` package to open the backup database file.
2. run the `VACUUM INTO ?` statement on the backup database, targetting the
   path of your application's database (the one you pass to `NativeDatabase`).
