@internal
library;

import 'package:meta/meta.dart';

import 'tokenizer/token.dart';

/// An active error recovery context in the parser.
///
/// The current error recovery context is represented as a stack of
/// [ErrorRecoveryScope]s.
/// When an error is encountered, the parser skips tokens until [indicatesEnd]
/// returns true on any recovery scope.
sealed class ErrorRecoveryScope {
  /// Whether [token] indicates the end of this error recovery scope, meaning
  /// that we can stop a synchronization run here.
  bool indicatesEnd(Token token);
}

/// An error recovery scope used when parsing statements. It will skip over to
/// the next semicolon when we have an unrecoverable error in the statement so
/// that we can at least parse subsequent statements.
final class InStatement implements ErrorRecoveryScope {
  const InStatement();

  @override
  bool indicatesEnd(Token token) {
    return token.type == TokenType.semicolon;
  }
}

/// An error recovery scope used for elements separated by comma.
///
/// When encountering an error parsing an element, we can skip to the next comma
/// and attempt to parse other elements to recover a larger part of the AST.
final class InCommaSeparatedList implements ErrorRecoveryScope {
  @override
  bool indicatesEnd(Token token) {
    return token.type == TokenType.comma;
  }
}

/// An error recovery scope used for things in parentheses.
///
/// When encountering an error inside the parentheses, we can skip to the
/// matching closing parenthesis if it has been inferred via [Token.match] in
/// the scanner. This mainly avoids skipping too much when no other precise
/// scope is active.
final class InParentheses implements ErrorRecoveryScope {
  final Token leftParentheses;
  final Token? rightParenthesis;

  InParentheses(this.leftParentheses, this.rightParenthesis);

  @override
  bool indicatesEnd(Token token) {
    return token == rightParenthesis;
  }
}
