import 'dart:io';

import 'package:drift/drift.dart';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return driftDatabase(
    // By default, drift creates a file named app.sqlite based on the name here.
    // Because we need to interact with the underlying file, we add the
    // `databasePath` option to specify the exact path here.
    name: 'app',
    native: DriftNativeOptions(
      databasePath: () async {
        // put the database file, called db.sqlite here, into the documents
        // folder for your app.
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'app.db'));

        if (!await file.exists()) {
          // Extract the pre-populated database file from assets
          final blob = await rootBundle.load('assets/my_database.db');
          final buffer = blob.buffer;
          await file.writeAsBytes(
            buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
          );
        }

        return file.path;
      },
    ),
  );
}
