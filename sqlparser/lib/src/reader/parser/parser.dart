import 'package:sqlparser/src/ast/expressions/expressions.dart';
import 'package:sqlparser/src/ast/expressions/unary.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

class Parser {
  final List<Token> tokens;
  int _current = 0;

  Parser(this.tokens);

  bool get _isAtEnd => _peek.type == TokenType.eof;
  Token get _peek => tokens[_current];
  Token get _previous => tokens[_current - 1];

  bool _match(List<TokenType> types) {
    for (var type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

  Token _advance() {
    if (!_isAtEnd) {
      _current++;
    }
    return _previous;
  }

  /* We parse expressions here.
  * Operators have the following precedence:
  *  - + ~ NOT (unary)
  *  || (concatenation)
  *  * / %
  *  + -
  *  << >> & |
  *  < <= > >=
  *  = == != <> IS IS NOT  IN LIKE GLOB MATCH REGEXP
  *  AND
  *  OR
  *  We also treat expressions in parentheses and literals with the highest
  *  priority. Parsing methods are written in ascending precedence, and each
  *  parsing method calls the next higher precedence if unsuccessful.
  * */

  Expression expression() {
    return _unary();
  }

  Expression _unary() {
    if (_match(const [
      TokenType.minus,
      TokenType.plus,
      TokenType.tilde,
      TokenType.not
    ])) {
      final operator = _previous;
      final expression = _unary();
      return UnaryExpression(operator, expression);
    }

    return _primary();
  }

  Expression _primary() {
    return null;
  }
}
