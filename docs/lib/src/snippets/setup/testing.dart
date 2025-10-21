import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';
// the file defined above, you can test any drift database of course
import 'database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        // Recommended for widget tests to avoid test errors.
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() async {
    await database.close();
  });
}
