import 'package:drift/drift.dart';

// Demonstrates how table classes can derive a private class
// and only the public class will be included in drift generation
class MyPublicTable extends _$MyPrivateTable {
  TextColumn get nameFromPublicTable => text()();
}

class _$MyPrivateTable extends Table {
  TextColumn get nameFromPrivateTable => text()();
}
