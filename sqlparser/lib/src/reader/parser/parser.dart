import 'package:meta/meta.dart';
import 'package:sqlparser/src/ast/expressions/expressions.dart';
import 'package:sqlparser/src/ast/expressions/literals.dart';
import 'package:sqlparser/src/ast/expressions/simple.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

const _comparisonOperators = [
  TokenType.less,
  TokenType.lessEqual,
  TokenType.more,
  TokenType.moreEqual,
];
const _binaryOperators = const [
  TokenType.shiftLeft,
  TokenType.shiftRight,
  TokenType.ampersand,
  TokenType.pipe,
];

class ParsingError implements Exception {
  final Token token;
  final String message;

  ParsingError(this.token, this.message);
}

// todo better error handling and synchronisation, like it's done here:
// https://craftinginterpreters.com/parsing-expressions.html#synchronizing-a-recursive-descent-parser

class Parser {
  final List<Token> tokens;
  final List<ParsingError> errors = [];
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

  @alwaysThrows
  void _error(String message) {
    final error = ParsingError(_peek, message);
    errors.add(error);
    throw error;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    _error(message);
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
  *  https://www.sqlite.org/lang_expr.html
  * */

  Expression expression() {
    return _or();
  }

  /// Parses an expression of the form a <T> b, where <T> is in [types] and
  /// both a and b are expressions with a higher precedence parsed from
  /// [higherPrecedence].
  Expression _parseSimpleBinary(
      List<TokenType> types, Expression Function() higherPrecedence) {
    var expression = higherPrecedence();

    while (_match(types)) {
      final operator = _previous;
      final right = higherPrecedence();
      expression = BinaryExpression(expression, operator, right);
    }
    return expression;
  }

  Expression _or() => _parseSimpleBinary(const [TokenType.or], _and);
  Expression _and() => _parseSimpleBinary(const [TokenType.and], _equals);

  Expression _equals() {
    var expression = _comparison();
    final ops = const [
      TokenType.equal,
      TokenType.doubleEqual,
      TokenType.exclamationEqual,
      TokenType.lessMore,
      TokenType.$is,
      TokenType.$in,
      TokenType.like,
      TokenType.glob,
      TokenType.match,
      TokenType.regexp,
    ];

    while (_match(ops)) {
      final operator = _previous;
      if (operator.type == TokenType.$is) {
        final not = _match(const [TokenType.not]);
        // special case: is not expression
        expression = IsExpression(not, expression, _comparison());
      } else {
        expression = BinaryExpression(expression, operator, _comparison());
      }
    }
    return expression;
  }

  Expression _comparison() {
    return _parseSimpleBinary(_comparisonOperators, _binaryOperation);
  }

  Expression _binaryOperation() {
    return _parseSimpleBinary(_binaryOperators, _addition);
  }

  Expression _addition() {
    return _parseSimpleBinary(const [
      TokenType.plus,
      TokenType.minus,
    ], _multiplication);
  }

  Expression _multiplication() {
    return _parseSimpleBinary(const [
      TokenType.star,
      TokenType.slash,
      TokenType.percent,
    ], _concatenation);
  }

  Expression _concatenation() {
    return _parseSimpleBinary(const [TokenType.doublePipe], _unary);
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
    final token = _advance();
    final type = token.type;
    switch (type) {
      case TokenType.numberLiteral:
        // todo get the proper value out of this one
        return NumericLiteral(42, _peek);
      case TokenType.stringLiteral:
        final token = _peek as StringLiteralToken;
        return StringLiteral(token);
      case TokenType.$null:
        return NullLiteral(_peek);
      case TokenType.$true:
        return BooleanLiteral.withTrue(_peek);
      case TokenType.$false:
        return BooleanLiteral.withFalse(_peek);
      // todo CURRENT_TIME, CURRENT_DATE, CURRENT_TIMESTAMP
      case TokenType.leftParen:
        final left = _previous;
        final expr = expression();
        _consume(TokenType.rightParen, 'Expected a closing bracket');
        return Parentheses(left, expr, _previous);
      default:
        break;
    }

    // nothing found -> issue error
    _error('Could not parse this expression');
  }
}
