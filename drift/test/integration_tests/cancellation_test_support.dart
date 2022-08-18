import 'package:drift/drift.dart';
import 'package:drift/native.dart';

DatabaseConnection createConnection() {
  var counter = 0;
  final loggedValues = <int>[];

  return DatabaseConnection(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.createFunction(
          functionName: 'increment_counter',
          function: (args) => counter++,
        );
        rawDb.createFunction(
          functionName: 'get_counter',
          function: (args) => counter,
        );

        rawDb.createFunction(
          functionName: 'log_value',
          function: (args) {
            final value = args.single as int;
            loggedValues.add(value);
            return value;
          },
        );
        rawDb.createFunction(
          functionName: 'get_values',
          function: (args) => loggedValues.join(','),
        );
      },
    ),
  );
}

class EmptyDb extends GeneratedDatabase {
  EmptyDb.connect(DatabaseConnection c) : super.connect(c);
  @override
  final List<TableInfo> allTables = const [];
  @override
  final int schemaVersion = 1;
}
