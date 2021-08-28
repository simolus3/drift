import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

extension ExpectErrors on AnalysisContext {
  void expectError(String lexeme, {AnalysisErrorType? type}) {
    expect(
      errors,
      [analysisErrorWith(lexeme: lexeme, type: type)],
    );
  }

  void expectNoError() {
    expect(errors, isEmpty);
  }
}

Matcher analysisErrorWith({String? lexeme, AnalysisErrorType? type}) {
  var matcher = isA<AnalysisError>();

  if (lexeme != null) {
    matcher = matcher.having((e) => e.span?.text, 'span.text', lexeme);
  }
  if (type != null) {
    matcher = matcher.having((e) => e.type, 'type', type);
  }

  return matcher;
}
