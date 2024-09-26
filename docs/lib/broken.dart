import 'package:drift/drift.dart';

class BrokenTable extends Table {
  IntColumn get unknownRef => integer().customConstraint('CHECK foo > 10')();
}
