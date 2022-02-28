import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('reports error when using different-length tuples in VALUES', () {
    final stmt = SqlEngine().analyze('VALUES (1, 2), (3)');

    expect(
      stmt.errors,
      contains(
        isA<AnalysisError>()
            .having((e) => e.type, 'type',
                AnalysisErrorType.valuesSelectCountMismatch)
            .having((e) => e.message, 'message',
                allOf(contains('1'), contains('2')))
            .having((e) => e.relevantNode!.span!.text, 'relevantNode.span.text',
                '(3)'),
      ),
    );
  });
}
