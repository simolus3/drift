// A full cross-platform example is available here: https://github.com/simolus3/drift/tree/develop/examples/app

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

QueryExecutor executorWithSqflite() {
  return SqfliteQueryExecutor.inDatabaseFolder(path: 'app.db');
}
