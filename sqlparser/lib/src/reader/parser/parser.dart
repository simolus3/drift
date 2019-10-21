import 'package:meta/meta.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
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
  final AutoCompleteEngine autoComplete;

  /// Whether to enable the extensions moor makes to the sql grammar.
  final bool enableMoorExtensions;

  int _current = 0;

  ParserBase(this.tokens, this.enableMoorExtensions, this.autoComplete);

  bool get _reportAutoComplete => autoComplete != null;

  void _suggestHint(HintDescription description) {
    final tokenBefore = _current == 0 ? null : _previous;
    autoComplete?.addHint(Hint(tokenBefore, description));
  }

  void _suggestHintForTokens(Iterable<TokenType> types) {
    final relevant =
        types.where(isKeyword).map((type) => HintDescription.token(type));
    final description = CombinedDescription()..descriptions.addAll(relevant);
    _suggestHint(description);
  }

  void _suggestHintForToken(TokenType type) {
    if (isKeyword(type)) {
      _suggestHint(HintDescription.token(type));
    }
  }

  bool get _isAtEnd => _peek.type == TokenType.eof;
  Token get _peek => tokens[_current];
  Token get _peekNext => tokens[_current + 1];
  Token get _previous => tokens[_current - 1];

  bool _match(Iterable<TokenType> types) {
    if (_reportAutoComplete) _suggestHintForTokens(types);
    for (var type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _matchOne(TokenType type) {
    if (_reportAutoComplete) _suggestHintForToken(type);
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
    if (_reportAutoComplete) _suggestHintForToken(type);
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

  /// Returns whether the next token is an [TokenType.identifier] or a
  /// [KeywordToken]. If this method returns true, calling [_consumeIdentifier]
  /// with same [lenient] parameter will now throw.
  bool _checkIdentifier({bool lenient = false}) {
    final next = _peek;
    if (next.type == TokenType.identifier) return true;

    return next is KeywordToken && (next.canConvertToIdentifier() || lenient);
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

  /// Consumes an identifier.
  IdentifierToken _consumeIdentifier(String message, {bool lenient = false}) {
    final next = _peek;
    // non-standard keywords can be parsed as an identifier, we allow all
    // keywords when lenient is true
    if (next is KeywordToken && (next.canConvertToIdentifier() || lenient)) {
      return (_advance() as KeywordToken).convertToIdentifier();
    }
    return _consume(TokenType.identifier, message) as IdentifierToken;
  }

  // Common operations that we are referenced very often
  Expression expression();

  /// Parses a [Tuple]. If [orSubQuery] is set (defaults to false), a [SubQuery]
  /// (in brackets) will be accepted as well.
  Expression _consumeTuple({bool orSubQuery = false});

  /// Parses a [BaseSelectStatement], which is either a [SelectStatement] or a
  /// [CompoundSelectStatement]. If [noCompound] is set to true, the parser will
  /// only attempt to parse a [SelectStatement].
  ///
  /// See also:
  /// https://www.sqlite.org/lang_select.html
  BaseSelectStatement select({bool noCompound});

  Literal _literalOrNull();
  OrderingMode _orderingModeOrNull();

  /// https://www.sqlite.org/syntax/window-defn.html
  WindowDefinition _windowDefinition();

  /// Parses a block, which consists of statements between `BEGIN` and `END`.
  Block _consumeBlock();
}

class Parser extends ParserBase
    with ExpressionParser, SchemaParser, CrudParser {
  Parser(List<Token> tokens,
      {bool useMoor = false, AutoCompleteEngine autoComplete})
      : super(tokens, useMoor, autoComplete);

  // todo remove this and don't be that lazy in moorFile()
  var _lastStmtHadParsingError = false;

  Statement statement() {
    final first = _peek;
    Statement stmt = _crud();
    stmt ??= _create();

    if (enableMoorExtensions) {
      stmt ??= _import() ?? _declaredStatement();
    }

    if (stmt == null) {
      _error('Expected a sql statement to start here');
    }

    if (_matchOne(TokenType.semicolon)) {
      stmt.semicolon = _previous;
    }

    if (!_isAtEnd) {
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

  MoorFile moorFile() {
    final first = _peek;
    final foundComponents = <PartOfMoorFile>[];

    // (we try again if the last statement had a parsing error)

    // first, parse import statements
    for (var stmt = _parseAsStatement(_import);
        stmt != null || _lastStmtHadParsingError;
        stmt = _parseAsStatement(_import)) {
      foundComponents.add(stmt);
    }

    // next, table declarations
    for (var stmt = _parseAsStatement(_create);
        stmt != null || _lastStmtHadParsingError;
        stmt = _parseAsStatement(_create)) {
      foundComponents.add(stmt);
    }

    // finally, declared statements
    for (var stmt = _parseAsStatement(_declaredStatement);
        stmt != null || _lastStmtHadParsingError;
        stmt = _parseAsStatement(_declaredStatement)) {
      foundComponents.add(stmt);
    }

    if (!_isAtEnd) {
      _error('Expected the file to end here.');
    }

    foundComponents.removeWhere((c) => c == null);

    final file = MoorFile(foundComponents);
    if (foundComponents.isNotEmpty) {
      file.setSpan(first, _previous);
    } else {
      file.setSpan(first, first); // empty file
    }
    return file;
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
      final name = _consumeIdentifier('Expected a name for a declared query');
      final colon =
          _consume(TokenType.colon, 'Expected colon (:) followed by a query');

      final stmt = _crud();

      return DeclaredStatement(name.identifier, stmt)
        ..identifier = name
        ..colon = colon;
    }

    return null;
  }

  /// Invokes [parser], sets the appropriate source span and attaches a
  /// semicolon if one exists.
  T _parseAsStatement<T extends Statement>(T Function() parser) {
    _lastStmtHadParsingError = false;
    final first = _peek;
    T result;
    try {
      result = parser();
    } on ParsingError catch (_) {
      _lastStmtHadParsingError = true;
      // the error is added to the list errors, so ignore. We skip to the next
      // semicolon to parse the next statement.
      _synchronize();
    }

    if (result == null) return null;

    if (_matchOne(TokenType.semicolon)) {
      result.semicolon = _previous;
    }

    result.setSpan(first, _previous);
    return result;
  }

  @override
  Block _consumeBlock() {
    final begin = _consume(TokenType.begin, 'Expected BEGIN');
    final stmts = <CrudStatement>[];

    for (var stmt = _parseAsStatement(_crud);
        stmt != null || _lastStmtHadParsingError;
        stmt = _parseAsStatement(_crud)) {
      if (stmt != null) stmts.add(stmt);
    }

    final end = _consume(TokenType.end, 'Expected END');

    return Block(stmts)
      ..setSpan(begin, end)
      ..begin = begin
      ..end = end;
  }

  void _synchronize() {
    // fast-forward to the token after the next semicolon
    while (!_isAtEnd && _advance().type != TokenType.semicolon) {}
  }
}
