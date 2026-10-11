import 'package:drift3_preview/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text();
}
