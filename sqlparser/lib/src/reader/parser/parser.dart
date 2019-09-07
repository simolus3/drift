import 'package:meta/meta.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

part 'crud.dart';
part 'num_parser.dart';
part 'expressions.dart';
part 'schema.dart';

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

final _startOperators = const [
  TokenType.natural,
  TokenType.left,
  TokenType.inner,
  TokenType.cross,
  TokenType.join,
];

class ParsingError implements Exception {
  final Token token;
  final String message;

  ParsingError(this.token, this.message);

  @override
  String toString() {
    return token.span.message('Error: $message}');
  }
}

abstract class ParserBase {
  final List<Token> tokens;
  final List<ParsingError> errors = [];

  /// Whether to enable the extensions moor makes to the sql grammar.
  final bool enableMoorExtensions;

  int _current = 0;

  ParserBase(this.tokens, this.enableMoorExtensions);

  bool get _isAtEnd => _peek.type == TokenType.eof;
  Token get _peek => tokens[_current];
  Token get _peekNext => tokens[_current + 1];
  Token get _previous => tokens[_current - 1];

  bool _match(Iterable<TokenType> types) {
    for (var type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _matchOne(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  /// Returns true if the next token is [type] or if the next two tokens are
  /// "NOT" followed by [type]. Does not consume any tokens.
  bool _checkWithNot(TokenType type) {
    if (_check(type)) return true;
    if (_check(TokenType.not) && _peekNext.type == type) return true;
    return false;
  }

  /// Like [_checkWithNot], but with more than one token type.
  bool _checkAnyWithNot(List<TokenType> types) {
    if (types.any(_check)) return true;
    if (_check(TokenType.not) && types.contains(_peekNext.type)) return true;
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

  /// Steps back a token. This needs to be used very carefully. We basically
  /// only use it in [ExpressionParser._primary] because we unconditionally
  /// [_advance] in there and we'd like to report more accurate errors when no
  /// matching token was found.
  void _stepBack() {
    if (_current != null) {
      _current--;
    }
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

  /// Consumes an identifier. If [lenient] is true and the next token is not
  /// an identifier but rather a [KeywordToken], that token will be converted
  /// to an identifier.
  IdentifierToken _consumeIdentifier(String message, {bool lenient = false}) {
    if (lenient && _peek is KeywordToken) {
      return (_advance() as KeywordToken).convertToIdentifier();
    }
    return _consume(TokenType.identifier, message) as IdentifierToken;
  }

  // Common operations that we are referenced very often
  Expression expression();
  TupleExpression _consumeTuple();

  /// Parses a [SelectStatement], or returns null if there is no select token
  /// after the current position.
  ///
  /// See also:
  /// https://www.sqlite.org/lang_select.html
  SelectStatement select();

  Literal _literalOrNull();
  OrderingMode _orderingModeOrNull();

  /// https://www.sqlite.org/syntax/window-defn.html
  WindowDefinition _windowDefinition();
}

class Parser extends ParserBase
    with ExpressionParser, SchemaParser, CrudParser {
  Parser(List<Token> tokens, {bool useMoor = false}) : super(tokens, useMoor);

  Statement statement({bool expectEnd = true}) {
    final first = _peek;
    Statement stmt = _crud();
    stmt ??= _createTable();

    if (enableMoorExtensions) {
      stmt ??= _import() ?? _declaredStatement();
    }

    if (stmt == null) {
      _error('Expected a sql statement to start here');
    }

    if (_matchOne(TokenType.semicolon)) {
      stmt.semicolon = _previous;
    }

    if (!_isAtEnd && expectEnd) {
      _error('Expected the statement to finish here');
    }
    return stmt..setSpan(first, _previous);
  }

  CrudStatement _crud() {
    // writing select() ?? _deleteStmt() and so on doesn't cast to CrudStatement
    // for some reason.
    CrudStatement stmt = select();
    stmt ??= _deleteStmt();
    stmt ??= _update();
    stmt ??= _insertStmt();

    return stmt;
  }

  ImportStatement _import() {
    if (_matchOne(TokenType.import)) {
      final importToken = _previous;
      final import = _consume(TokenType.stringLiteral,
              'Expected import file as a string literal (single quoted)')
          as StringLiteralToken;

      return ImportStatement(import.value)
        ..importToken = importToken
        ..importString = import;
    }
    return null;
  }

  DeclaredStatement _declaredStatement() {
    if (_check(TokenType.identifier) || _peek is KeywordToken) {
      final name = _consumeIdentifier('Expected a name for a declared query',
          lenient: true);
      final colon =
          _consume(TokenType.colon, 'Expected colon (:) followed by a query');

      final stmt = _crud();

      return DeclaredStatement(name.identifier, stmt)
        ..identifier = name
        ..colon = colon;
    }

    return null;
  }

  List<Statement> statements() {
    final stmts = <Statement>[];
    while (!_isAtEnd) {
      try {
        stmts.add(statement(expectEnd: false));
      } on ParsingError catch (_) {
        // the error is added to the list errors, so ignore. We skip to the next
        // semicolon to parse the next statement.
        _synchronize();
      }
    }
    return stmts;
  }

  void _synchronize() {
    // fast-forward to the token after th next semicolon
    while (!_isAtEnd && _advance().type != TokenType.semicolon) {}
  }
}
