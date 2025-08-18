import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'verifier_common.dart';

final class NativeSchemaVerifier extends VerifierImplementation<Database>
    implements SchemaVerifier {
  NativeSchemaVerifier(super.helper, {super.setup});

  @override
  Database newInMemoryDatabase() {
    return sqlite3.openInMemory();
  }

  @override
  QueryExecutor wrapOpened(Database db,
      {required bool closeUnderlyingOnClose}) {
    return NativeDatabase.opened(db,
        closeUnderlyingOnClose: closeUnderlyingOnClose);
  }
}
