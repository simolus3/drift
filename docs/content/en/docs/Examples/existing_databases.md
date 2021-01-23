---
title: "Existing databases"
description: Using moor with an existing database
---

You can use moor with a pre-propulated database that you ship with your app.

## Including the database

First, create the sqlite3 database you want to ship with your app.
You can create a database with the [sqlite3 CLI tool](https://sqlite.org/cli.html)
on your development machine.
Of course, you can also create the database programmatically by using a library
like [sqlite3](https://pub.dev/packages/sqlite3) (or even moor itself).

To ship that database to users, you can include it as a [flutter asset](https://flutter.dev/docs/development/ui/assets-and-images).
Simply include it in your pubspec:

```yaml
flutter:
  assets:
    - assets/my_database.db
```

## Extracting the database

To initialize the database before using moor, you need to extract the asset from your
app onto the device.
In moor, you can use a [LazyDatabase](https://pub.dev/documentation/moor/latest/moor/LazyDatabase-class.html)
to perform that work just before your moor database is opened:

```dart
import 'package:moor/moor.dart';
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
@UseMoor(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  // ...
```