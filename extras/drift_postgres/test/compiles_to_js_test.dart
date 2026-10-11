@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:drift_postgres/drift_postgres.dart';

void main() {
  test('postgres package can compile with dart2js', () async {
    // Some users have shared packages depending on drift_postgres for backends
    // and the core drift package for frontend connections.
    // Make sure that, despite not supporting the web as a platform, this
    // package can be compiled for those setups.
    // https://github.com/simolus3/drift/pull/3030#issuecomment-2147867478
    PgTypes.bigIntArray;
  });
}
