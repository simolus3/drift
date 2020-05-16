import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';

void main() {
  test('reports column name mismatches in CREATE VIEW statements', () {
    final engine = SqlEngine()..registerTable(demoTable);
    final result = engine.analyze('CREATE VIEW my_view (foo) AS '
        'SELECT * FROM demo;');

    expect(result.errors, hasLength(1));
    final error = result.errors.single;

    expect(error.type, AnalysisErrorType.viewColumnNamesMismatch);
  });
}
