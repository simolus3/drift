import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('is forbidden on older sqlite versions', () {
    final engine = SqlEngine();
    final result = engine.analyze('SELECT iif (0, 1)');

    expect(result.errors, [
      analysisErrorWith(
          lexeme: '0, 1',
          type: AnalysisErrorType.invalidAmountOfParameters,
          message: 'iif expects 3 arguments, got 2.'),
    ]);
  });

  test('sum', () {
    final engine = SqlEngine();
    final result = engine.analyze('SELECT sum(1, 2, 3)');

    result.expectError(
      '1, 2, 3',
      type: AnalysisErrorType.invalidAmountOfParameters,
    );
  });
}
