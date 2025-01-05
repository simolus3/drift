import 'package:drift/drift.dart';
import 'type.dart';

class PeriodicReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  Column<Duration> get frequency => customType(const DurationType())
      .clientDefault(() => Duration(minutes: 15))();
  TextColumn get reminder => text()();
}
