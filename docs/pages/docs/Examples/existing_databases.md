---
data:
  title: "Existing databases"
  description: Using drift with an existing database
template: layouts/docs/single
---

You can use drift with a pre-propulated database that you ship with your app.

## Including the database

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

## Extracting the database

To initialize the database before using drift, you need to extract the asset from your
app onto the device.
In drift, you can use a [LazyDatabase](https://pub.dev/documentation/drift/latest/drift/LazyDatabase-class.html)
to perform that work just before your drift database is opened:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    
    if (!await file.exists()) {
        // Extract the pre-populated datbaase file from assets
        final blob = await rootBundle.load('assets/my_database.db');
        await file.writeAsBytes(blob);
    }

    return VmDatabase(file);
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