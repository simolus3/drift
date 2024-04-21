import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

extension ExpectErrors on AnalysisContext {
  void expectError(String lexeme, {AnalysisErrorType? type, message}) {
    expect(
      errors,
      [analysisErrorWith(lexeme: lexeme, type: type, message: message)],
    );
  }

  void expectNoError() {
    expect(errors, isEmpty);
  }
}

Matcher analysisErrorWith({String? lexeme, AnalysisErrorType? type, message}) {
  var matcher = isA<AnalysisError>();

  if (lexeme != null) {
    matcher = matcher.having((e) => e.span?.text, 'span.text', lexeme);
  }
  if (type != null) {
    matcher = matcher.having((e) => e.type, 'type', type);
  }
  if (message != null) {
    matcher = matcher.having((e) => e.message, 'message', message);
  }

  return matcher;
}
