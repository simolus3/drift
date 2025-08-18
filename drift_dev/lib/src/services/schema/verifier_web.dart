import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:drift_dev/api/migrations_web.dart' as api;

import 'verifier_common.dart';

final class WebSchemaVerifier extends VerifierImplementation<CommonDatabase>
    implements api.WebSchemaVerifier {
  final CommonSqlite3 sqlite3;

  WebSchemaVerifier(this.sqlite3, super.helper, {super.setup});

  @override
  CommonDatabase newInMemoryDatabase() {
    return sqlite3.openInMemory();
  }

  @override
  QueryExecutor wrapOpened(CommonDatabase db,
      {required bool closeUnderlyingOnClose}) {
    return WasmDatabase.opened(db,
        closeUnderlyingOnClose: closeUnderlyingOnClose);
  }
}
