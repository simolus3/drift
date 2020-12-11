import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('does not throw when parsing invalid statements', () {
    final engine = SqlEngine();
    late ParseResult result;

    try {
      result = engine.parse('UDPATE foo SET bar = foo;');
    } on ParsingError {
      fail('Calling engine.parse threw an error');
    }

    expect(result.errors, isNotEmpty);
  });

  test('does not throw when analyzing invalid statements', () {
    final engine = SqlEngine();
    late AnalysisContext result;

    try {
      result = engine.analyze('UDPATE foo SET bar = foo;');
    } on ParsingError {
      fail('Calling engine.parse threw an error');
    }

    expect(result.errors, isNotEmpty);
  });
}
