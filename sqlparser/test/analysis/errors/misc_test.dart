import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../data.dart';
import 'utils.dart';

void main() {
  final engine = SqlEngine()..registerTable(demoTable);

  test('warns about multiple parameters with DISTINCT', () {
    engine
        .analyze("SELECT group_concat(DISTINCT content, '-') FROM demo")
        .expectError('DISTINCT',
            type: AnalysisErrorType.distinctAggregateWithWrongParameterCount);
  });
}
