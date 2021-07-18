import 'package:moor/ffi.dart';
import 'package:tests/tests.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning {
    return true;
  }

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(
        PgDatabase.open('localhost', 5432, 'westito', username: 'westito'));
  }

  @override
  Future deleteData() async {
    // Manually delete tables
  }
}

void main() {
  // Manually delete tables before run
  runAllTests(PgExecutor());
}
