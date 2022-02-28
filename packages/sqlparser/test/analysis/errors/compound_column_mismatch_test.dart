import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  test('reports column count mismatch in compound select query', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final result = engine.analyze('SELECT * FROM demo UNION SELECT 1');

    expect(result.errors, hasLength(1));
    final error = result.errors.single;

    expect(error.type, AnalysisErrorType.compoundColumnCountMismatch);
  });
}
