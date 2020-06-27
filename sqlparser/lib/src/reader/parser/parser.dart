import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
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
const _binaryOperators = [
  TokenType.shiftLeft,
  TokenType.shiftRight,
  TokenType.ampersand,
  TokenType.pipe,
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
    for (final type in types) {
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
  Null _error(String message) {
    final error = ParsingError(_peek, message);
    errors.add(error);
    throw error;
  }

  Token _consume(TokenType type, [String message]) {
    if (_check(type)) return _advance();

    _error(message ?? 'Expected $type');
  }

  /// Consumes an identifier.
  IdentifierToken _consumeIdentifier(String message, {bool lenient = false}) {
    final next = _peek;
    // non-standard keywords can be parsed as an identifier, we allow all
    // keywords when lenient is true
    if (next is KeywordToken && (next.canConvertToIdentifier() || lenient)) {
      return (_advance() as KeywordToken).convertToIdentifier();
    }

    if (next is KeywordToken) {
      message = '$message (got keyword ${reverseKeywords[next.type]})';
    }

    return _consume(TokenType.identifier, message) as IdentifierToken;
  }

  // Common operations that we are referenced very often
  Expression expression();

  List<Token> _typeName();

  /// Parses a [Tuple]. If [orSubQuery] is set (defaults to false), a [SubQuery]
  /// (in brackets) will be accepted as well.
  Expression _consumeTuple({bool orSubQuery = false});

  /// Parses a [BaseSelectStatement], which is either a [SelectStatement] or a
  /// [CompoundSelectStatement]. If [noCompound] is set to true, the parser will
  /// only attempt to parse a [SelectStatement].
  ///
  /// This method doesn't parse WITH clauses, most users would probably want to
  /// use [_fullSelect] instead.
  ///
  /// See also:
  /// https://www.sqlite.org/lang_select.html
  BaseSelectStatement select({bool noCompound});

  /// Parses a select statement as defined in [the sqlite documentation][s-d],
  /// which means that compound selects and a with clause is supported.
  ///
  /// [s-d]: https://sqlite.org/syntax/select-stmt.html
  BaseSelectStatement _fullSelect();

  Variable _variableOrNull();
  Literal _literalOrNull();
  OrderingMode _orderingModeOrNull();

  /// https://www.sqlite.org/syntax/window-defn.html
  WindowDefinition _windowDefinition();

  /// Parses a block, which consists of statements between `BEGIN` and `END`.
  Block _consumeBlock();

  /// Parses function parameters, without the surrounding parentheses.
  FunctionParameters _functionParameters();

  List<IndexedColumn> _indexedColumns();

  /// Skips all tokens until it finds one with [type]. If [skipTarget] is true,
  /// that token will be skipped as well.
  ///
  /// When using `_synchronize(TokenType.semicolon, skipTarget: true)`,
  /// this will move the parser to the next statement, which can be useful for
  /// error recovery.
  void _synchronize(TokenType type, {bool skipTarget = false}) {
    if (skipTarget) {
      while (!_isAtEnd && _advance().type != type) {}
    } else {
      while (!_isAtEnd && !_check(type)) {
        _advance();
      }
    }
  }
}

class Parser extends ParserBase
    with ExpressionParser, SchemaParser, CrudParser {
  Parser(List<Token> tokens,
      {bool useMoor = false, AutoCompleteEngine autoComplete})
      : super(tokens, useMoor, autoComplete);

  // todo remove this and don't be that lazy in moorFile()
  var _lastStmtHadParsingError = false;

  /// Parses a statement without throwing when there's a parsing error.
  Statement safeStatement() {
    return _parseAsStatement(statement, requireSemicolon: false) ??
        InvalidStatement();
  }

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
    DeclaredStatementIdentifier identifier;

    if (_check(TokenType.identifier) || _peek is KeywordToken) {
      final name = _consumeIdentifier('Expected a name for a declared query',
          lenient: true);

      identifier = SimpleName(name.identifier)..identifier = name;
    } else if (_matchOne(TokenType.atSignVariable)) {
      final previous = _previous as AtSignVariableToken;

      identifier = SpecialStatementIdentifier(previous.name)
        ..nameToken = previous;
    } else {
      return null;
    }

    final parameters = <StatementParameter>[];
    if (_matchOne(TokenType.leftParen)) {
      do {
        final first = _peek;
        final variable = _variableOrNull();
        if (variable == null) {
          _error('Expected a variable here');
        }
        final as = _consume(TokenType.as, 'Expected AS followed by a type');

        final typeNameTokens = _typeName();
        if (typeNameTokens == null) {
          _error('Expected a type name here');
        }

        final typeName = typeNameTokens.lexeme;
        parameters.add(VariableTypeHint(variable, typeName)
          ..as = as
          ..setSpan(first, _previous));
      } while (_matchOne(TokenType.comma));

      _consume(TokenType.rightParen, 'Expected closing parenthesis');
    }

    String as;
    if (_matchOne(TokenType.as)) {
      as = _consumeIdentifier('Expected a name of the result class').identifier;
    }

    final colon =
        _consume(TokenType.colon, 'Expected a colon (:) followed by a query');
    final stmt = _crud();

    if (stmt == null) {
      _error(
          'Expected a sql statement here (SELECT, UPDATE, INSERT or DELETE)');
    }

    return DeclaredStatement(
      identifier,
      stmt,
      parameters: parameters,
      as: as,
    )..colon = colon;
  }

  /// Invokes [parser], sets the appropriate source span and attaches a
  /// semicolon if one exists.
  T _parseAsStatement<T extends Statement>(T Function() parser,
      {bool requireSemicolon = true}) {
    _lastStmtHadParsingError = false;
    final first = _peek;
    T result;
    try {
      result = parser();

      if (result != null && requireSemicolon) {
        result.semicolon = _consume(TokenType.semicolon,
            'Expected a semicolon after the statement ended');
        result.setSpan(first, _previous);
      }
    } on ParsingError {
      _lastStmtHadParsingError = true;
      // the error is added to the list errors, so ignore. We skip after the
      // next semicolon to parse the next statement.
      _synchronize(TokenType.semicolon, skipTarget: true);

      if (result == null) return null;

      if (_matchOne(TokenType.semicolon)) {
        result.semicolon = _previous;
      }

      result.setSpan(first, _previous);
    }

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
}

extension on List<Token> {
  String get lexeme => first.span.expand(last.span).text;
}
