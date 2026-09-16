import 'dart:io';

import 'package:drift/drift.dart';
// #docregion new-native
import 'package:drift/native.dart';

// #enddocregion new-native
// #docregion new-sqflite
import 'package:drift_sqflite/drift_sqflite.dart';

// #enddocregion new-sqflite
// #docregion new-flutter
import 'package:drift_flutter/drift_flutter.dart';

// #enddocregion new-flutter
import 'package:sqflite_common/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

// ignore: unused_element
void _stubUse() {
  _oldSqflite();
  _oldSqlite();
  _NewSqflite._openDatabase();
  _NewNative._openDatabase();
  _NewDriftFlutter._openDatabase();
}

Future<void> _oldSqflite() async {
  // #docregion old-sqflite
  var databasesPath = await getDatabasesPath();
  var path = p.join(databasesPath, 'demo.db');
  var database = await openDatabase(path, version: 1);
  // #enddocregion old-sqflite

  database.close();
}

Future<void> _oldSqlite() async {
  // #docregion old-sqlite
  var dbFolder = await getApplicationDocumentsDirectory();
  var path = p.join(dbFolder.path, 'demo.db');
  var database = sqlite3.open(path);
  // #enddocregion old-sqlite

  database.close();
}

class _NewSqflite {
  // #docregion new-sqflite
  static QueryExecutor _openDatabase() {
    return SqfliteQueryExecutor.inDatabaseFolder(path: 'demo.db');
  }
  // #enddocregion new-sqflite
}

class _NewNative {
  // #docregion new-native
  static QueryExecutor _openDatabase() {
    return LazyDatabase(() async {
      var dbFolder = await getApplicationDocumentsDirectory();
      var file = File(p.join(dbFolder.path, 'demo.db'));

      return NativeDatabase.createInBackground(file);
    });
  }
  // #enddocregion new-native
}

class _NewDriftFlutter {
  // #docregion new-flutter
  static QueryExecutor _openDatabase() {
    return driftDatabase(
      name: 'demo',
      native: DriftNativeOptions(
        databasePath: () async {
          var dbFolder = await getApplicationDocumentsDirectory();
          return p.join(dbFolder.path, 'demo.db');
        },
      ),
    );
  }
  // #enddocregion new-flutter
}
