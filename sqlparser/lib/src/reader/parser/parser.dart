import 'package:source_span/source_span.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/engine/autocomplete/engine.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

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
    return token.span.message('Error: $message');
  }
}

class Parser {
  final List<Token> tokens;
  final List<ParsingError> errors = [];
  final AutoCompleteEngine? autoComplete;

  // todo remove this and don't be that lazy in moorFile()
  var _lastStmtHadParsingError = false;

  /// Whether to enable the extensions moor makes to the sql grammar.
  final bool enableMoorExtensions;

  int _current = 0;

  Parser(this.tokens, {bool useMoor = false, this.autoComplete})
      : enableMoorExtensions = useMoor;

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

  Never _error(String message) {
    final error = ParsingError(_peek, message);
    errors.add(error);
    throw error;
  }

  Token _consume(TokenType type, [String? message]) {
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

  /// Parses a statement without throwing when there's a parsing error.
  Statement safeStatement() {
    return _parseAsStatement(statement, requireSemicolon: false) ??
        InvalidStatement();
  }

  Statement statement() {
    final first = _peek;
    Statement? stmt = _crud();
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
    final foundComponents = <PartOfMoorFile?>[];

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

    final file = MoorFile(foundComponents.cast());
    if (foundComponents.isNotEmpty) {
      file.setSpan(first, _previous);
    } else {
      file.setSpan(first, first); // empty file
    }
    return file;
  }

  ImportStatement? _import() {
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

  DeclaredStatement? _declaredStatement() {
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
        parameters.add(_statementParameter());
      } while (_matchOne(TokenType.comma));

      _consume(TokenType.rightParen, 'Expected closing parenthesis');
    }

    String? as;
    if (_matchOne(TokenType.as)) {
      as = _consumeIdentifier('Expected a name of the result class').identifier;
    }

    final colon = _consume(
        TokenType.colon,
        'Expected a colon (:) followed by a query. Imports and CREATE '
        'statements must appear before the first query.');
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

  StatementParameter _statementParameter() {
    final first = _peek;
    final variable = _variableOrNull();

    if (variable != null) {
      // Type hint for a variable
      final as = _consume(TokenType.as, 'Expected AS followed by a type');
      final typeNameTokens = _typeName() ?? _error('Expected a type name here');
      final typeName = typeNameTokens.lexeme;

      var orNull = false;
      if (_matchOne(TokenType.or)) {
        _consume(TokenType.$null, 'Expected NULL to finish OR NULL');
        orNull = true;
      }

      return VariableTypeHint(variable, typeName, orNull: orNull)
        ..as = as
        ..setSpan(first, _previous);
    } else if (_matchOne(TokenType.dollarSignVariable)) {
      final placeholder = _previous as DollarSignVariableToken;
      _consume(TokenType.equal, 'Expected an equals sign here');
      final defaultValue = expression();

      return DartPlaceholderDefaultValue(placeholder.name, defaultValue)
        ..setSpan(placeholder, _previous)
        ..variableToken = placeholder;
    } else {
      _error('Expected a variable or a Dart placeholder here');
    }
  }

  /// Invokes [parser], sets the appropriate source span and attaches a
  /// semicolon if one exists.
  T? _parseAsStatement<T extends Statement>(T? Function() parser,
      {bool requireSemicolon = true}) {
    _lastStmtHadParsingError = false;
    final first = _peek;
    T? result;
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

  /// Parses a block, which consists of statements between `BEGIN` and `END`.
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
      expression = BinaryExpression(expression, operator, right)
        ..setSpan(expression.first!, _previous);
    }
    return expression;
  }

  Expression _or() => _parseSimpleBinary(const [TokenType.or], _and);
  Expression _and() => _parseSimpleBinary(const [TokenType.and], _in);

  Expression _in() {
    final left = _equals();

    if (_checkWithNot(TokenType.$in)) {
      final not = _matchOne(TokenType.not);
      _matchOne(TokenType.$in);

      final inside = _variableOrNull() ?? _consumeTuple(orSubQuery: true);
      return InExpression(left: left, inside: inside, not: not)
        ..setSpan(left.first!, _previous);
    }

    return left;
  }

  /// Parses expressions with the "equals" precedence. This contains
  /// comparisons, "IS (NOT) IN" expressions, between expressions and "like"
  /// expressions.
  Expression _equals() {
    var expression = _comparison();
    final first = expression.first;

    const ops = [
      TokenType.equal,
      TokenType.doubleEqual,
      TokenType.exclamationEqual,
      TokenType.lessMore,
      TokenType.$is,
    ];
    const stringOps = [
      TokenType.like,
      TokenType.glob,
      TokenType.match,
      TokenType.regexp,
    ];

    for (;;) {
      if (_checkWithNot(TokenType.between)) {
        final not = _matchOne(TokenType.not);
        _consume(TokenType.between, 'expected a BETWEEN');

        final lower = _comparison();
        _consume(TokenType.and, 'expected AND');
        final upper = _comparison();

        expression = BetweenExpression(
            not: not, check: expression, lower: lower, upper: upper)
          ..setSpan(first!, _previous);
      } else if (_match(ops)) {
        final operator = _previous;
        if (operator.type == TokenType.$is) {
          final not = _match(const [TokenType.not]);
          // special case: is not expression
          expression = IsExpression(not, expression, _comparison())
            ..setSpan(first!, _previous);
        } else {
          expression = BinaryExpression(expression, operator, _comparison())
            ..setSpan(first!, _previous);
        }
      } else if (_checkAnyWithNot(stringOps)) {
        final not = _matchOne(TokenType.not);
        _match(stringOps); // will consume, existence was verified with check
        final operator = _previous;

        final right = _comparison();
        Expression? escape;
        if (_matchOne(TokenType.escape)) {
          escape = _comparison();
        }

        expression = StringComparisonExpression(
            not: not,
            left: expression,
            operator: operator,
            right: right,
            escape: escape)
          ..setSpan(first!, _previous);
      } else {
        break; // no matching operator with this precedence was found
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
      TokenType.not,
    ])) {
      final operator = _previous;
      final expression = _unary();
      return UnaryExpression(operator, expression)
        ..setSpan(operator, expression.last!);
    } else if (_matchOne(TokenType.exists)) {
      final existsToken = _previous;
      _consume(
          TokenType.leftParen, 'Expected opening parenthesis after EXISTS');
      final selectStmt = _fullSelect() ?? _error('Expected a select statement');
      _consume(TokenType.rightParen,
          'Expected closing paranthesis to finish EXISTS expression');
      return ExistsExpression(select: selectStmt)
        ..setSpan(existsToken, _previous);
    }

    return _postfix();
  }

  Expression _postfix() {
    var expression = _case();

    // todo we don't currently parse "NOT NULL" (2 tokens) because of ambiguity
    // with NOT BETWEEN / NOT IN / ... expressions
    const matchedTokens = [
      TokenType.collate,
      TokenType.notNull,
      TokenType.isNull
    ];

    while (_match(matchedTokens)) {
      final operator = _previous;
      switch (operator.type) {
        case TokenType.collate:
          final collateOp = _previous;
          final collateFun =
              _consume(TokenType.identifier, 'Expected a collating sequence')
                  as IdentifierToken;
          expression = CollateExpression(
            inner: expression,
            operator: collateOp,
            collateFunction: collateFun,
          );
          break;
        case TokenType.isNull:
          expression = IsNullExpression(expression);
          break;
        case TokenType.notNull:
          expression = IsNullExpression(expression, true);
          break;
        default:
          // we checked with _match, this may never happen
          throw AssertionError();
      }
      expression.setSpan(operator, _previous);
    }

    return expression;
  }

  Expression _case() {
    if (_matchOne(TokenType.$case)) {
      final caseToken = _previous;

      final base = _check(TokenType.when) ? null : _primary();
      final whens = <WhenComponent>[];
      Expression? $else;

      while (_matchOne(TokenType.when)) {
        final whenToken = _previous;

        final whenExpr = _or();
        _consume(TokenType.then, 'Expected THEN');
        final then = expression();
        whens.add(WhenComponent(when: whenExpr, then: then)
          ..setSpan(whenToken, _previous));
      }

      if (_matchOne(TokenType.$else)) {
        $else = expression();
      }

      _consume(TokenType.end, 'Expected END to finish the case operator');
      return CaseExpression(whens: whens, base: base, elseExpr: $else)
        ..setSpan(caseToken, _previous);
    }

    return _primary();
  }

  Literal? _literalOrNull() {
    final token = _peek;

    Literal? _parseInner() {
      if (_matchOne(TokenType.numberLiteral)) {
        final number = token as NumericToken;
        return NumericLiteral(number.parsedNumber, token);
      }
      if (_matchOne(TokenType.stringLiteral)) {
        return StringLiteral(token as StringLiteralToken);
      }
      if (_matchOne(TokenType.$null)) {
        return NullLiteral(token);
      }
      if (_matchOne(TokenType.$true)) {
        return BooleanLiteral.withTrue(token);
      }
      if (_matchOne(TokenType.$false)) {
        return BooleanLiteral.withFalse(token);
      }

      const timeLiterals = {
        TokenType.currentTime: TimeConstantKind.currentTime,
        TokenType.currentDate: TimeConstantKind.currentDate,
        TokenType.currentTimestamp: TimeConstantKind.currentTimestamp,
      };

      if (_match(timeLiterals.keys)) {
        final token = _previous;
        return TimeConstantLiteral(timeLiterals[token.type]!, token);
      }

      return null;
    }

    final literal = _parseInner();
    literal?.setSpan(token, token);
    return literal;
  }

  Expression _primary() {
    final literal = _literalOrNull();
    if (literal != null) return literal;

    final variable = _variableOrNull();
    if (variable != null) return variable;

    if (_matchOne(TokenType.leftParen)) {
      final left = _previous;

      final selectStmt = _fullSelect(); // returns null if there's no select
      if (selectStmt != null) {
        _consume(TokenType.rightParen, 'Expected a closing bracket');
        return SubQuery(select: selectStmt)..setSpan(left, _previous);
      } else {
        final expr = expression();

        if (_matchOne(TokenType.comma)) {
          // It's a row value!
          final expressions = [expr];

          do {
            expressions.add(expression());
          } while (_matchOne(TokenType.comma));

          _consume(TokenType.rightParen, 'Expected a closing bracket');
          return Tuple(expressions: expressions, usedAsRowValue: true)
            ..setSpan(left, _previous);
        }

        _consume(TokenType.rightParen, 'Expected a closing bracket');
        return Parentheses(left, expr, _previous)..setSpan(left, _previous);
      }
    } else if (_matchOne(TokenType.dollarSignVariable)) {
      if (enableMoorExtensions) {
        final typedToken = _previous as DollarSignVariableToken;
        return DartExpressionPlaceholder(name: typedToken.name)
          ..token = typedToken
          ..setSpan(_previous, _previous);
      }
    } else if (_matchOne(TokenType.cast)) {
      final first = _previous;

      _consume(TokenType.leftParen, 'Expected opening parenthesis after CAST');
      final operand = expression();
      _consume(TokenType.as, 'Expected AS operator here');
      final type = _typeName()!;
      final typeName = type.lexeme;
      _consume(TokenType.rightParen, 'Expected closing bracket here');

      return CastExpression(operand, typeName)..setSpan(first, _previous);
    } else if (_checkIdentifier()) {
      final first = _consumeIdentifier(
          'This error message should never be displayed. Please report.');

      // could be table.column, function(...) or just column
      if (_matchOne(TokenType.dot)) {
        final second =
            _consumeIdentifier('Expected a column name here', lenient: true);
        return Reference(
            tableName: first.identifier, columnName: second.identifier)
          ..setSpan(first, second);
      } else if (_matchOne(TokenType.leftParen)) {
        // regular function invocation
        final parameters = _functionParameters();
        final rightParen = _consume(TokenType.rightParen,
            'Expected closing bracket after argument list');

        if (_peek.type == TokenType.filter || _peek.type == TokenType.over) {
          return _aggregate(first, parameters);
        }

        return FunctionExpression(
            name: first.identifier, parameters: parameters)
          ..setSpan(first, rightParen);
      } else {
        return Reference(columnName: first.identifier)..setSpan(first, first);
      }
    }

    if (_peek is KeywordToken) {
      _error('Could not parse this expression. Note: This is a reserved '
          'keyword, you can escape it in double ticks');
    } else {
      _error('Could not parse this expression');
    }
  }

  Variable? _variableOrNull() {
    if (_matchOne(TokenType.questionMarkVariable)) {
      return NumberedVariable(_previous as QuestionMarkVariableToken)
        ..setSpan(_previous, _previous);
    } else if (_matchOne(TokenType.colonVariable)) {
      return ColonNamedVariable(_previous as ColonVariableToken)
        ..setSpan(_previous, _previous);
    }
    return null;
  }

  /// Parses function parameters, without the surrounding parentheses.
  FunctionParameters _functionParameters() {
    if (_matchOne(TokenType.star)) {
      return StarFunctionParameter()
        ..starToken = _previous
        ..setSpan(_previous, _previous);
    }

    if (_check(TokenType.rightParen)) {
      // nothing between the brackets -> empty parameter list. We mark it as
      // synthetic because it has an empty span in the file
      return ExprFunctionParameters(parameters: const [])..synthetic = true;
    }

    final distinct = _matchOne(TokenType.distinct);
    final parameters = <Expression>[];
    final first = _peek;

    do {
      parameters.add(expression());
    } while (_matchOne(TokenType.comma));

    return ExprFunctionParameters(distinct: distinct, parameters: parameters)
      ..setSpan(first, _previous);
  }

  AggregateExpression _aggregate(
      IdentifierToken name, FunctionParameters params) {
    Expression? filter;

    // https://www.sqlite.org/syntax/filter.html (it's optional)
    if (_matchOne(TokenType.filter)) {
      _consume(TokenType.leftParen,
          'Expected opening parenthesis after filter statement');
      _consume(TokenType.where, 'Expected WHERE clause');
      filter = expression();
      _consume(TokenType.rightParen, 'Expecteded closing parenthes');
    }

    _consume(TokenType.over, 'Expected OVER to begin window clause');

    String? windowName;
    WindowDefinition? window;

    if (_matchOne(TokenType.identifier)) {
      windowName = (_previous as IdentifierToken).identifier;
    } else {
      window = _windowDefinition();
    }

    return AggregateExpression(
      function: name,
      parameters: params,
      filter: filter,
      windowDefinition: window,
      windowName: windowName,
    )..setSpan(name, _previous);
  }

  /// Parses a [Tuple]. If [orSubQuery] is set (defaults to false), a [SubQuery]
  /// (in brackets) will be accepted as well.
  Expression _consumeTuple({bool orSubQuery = false}) {
    final firstToken =
        _consume(TokenType.leftParen, 'Expected opening parenthesis for tuple');
    final expressions = <Expression>[];

    // if desired, attempt to parse select statement
    final subQuery = orSubQuery ? _fullSelect() : null;
    if (subQuery == null) {
      // no sub query found. read expressions that form the tuple.
      // tuples can be empty `()`, so only start parsing values when it's not
      if (_peek.type != TokenType.rightParen) {
        do {
          expressions.add(expression());
        } while (_matchOne(TokenType.comma));
      }

      _consume(
          TokenType.rightParen, 'Expected right parenthesis to close tuple');
      return Tuple(expressions: expressions)..setSpan(firstToken, _previous);
    } else {
      _consume(TokenType.rightParen,
          'Expected right parenthesis to finish subquery');
      return SubQuery(select: subQuery)..setSpan(firstToken, _previous);
    }
  }

  CrudStatement? _crud() {
    final withClause = _withClause();

    if (_check(TokenType.select) || _check(TokenType.$values)) {
      return select(withClause: withClause);
    } else if (_check(TokenType.delete)) {
      return _deleteStmt(withClause);
    } else if (_check(TokenType.update)) {
      return _update(withClause);
    } else if (_check(TokenType.insert) || _check(TokenType.replace)) {
      return _insertStmt(withClause);
    }
    return null;
  }

  WithClause? _withClause() {
    if (!_matchOne(TokenType.$with)) return null;
    final withToken = _previous;

    final recursive = _matchOne(TokenType.recursive);
    final recursiveToken = recursive ? _previous : null;

    final ctes = <CommonTableExpression>[];
    do {
      final name = _consumeIdentifier('Expected name for common table');
      List<String>? columnNames;

      // can optionally declare the column names in (foo, bar, baz) syntax
      if (_matchOne(TokenType.leftParen)) {
        columnNames = [];
        do {
          final identifier = _consumeIdentifier('Expected column name');
          columnNames.add(identifier.identifier);
        } while (_matchOne(TokenType.comma));

        _consume(TokenType.rightParen,
            'Expected closing bracket after column names');
      }

      final asToken = _consume(TokenType.as, 'Expected AS');

      const msg = 'Expected select statement in brackets';
      _consume(TokenType.leftParen, msg);
      final selectStmt = select() ?? _error(msg);
      _consume(TokenType.rightParen, msg);

      ctes.add(CommonTableExpression(
        cteTableName: name.identifier,
        columnNames: columnNames,
        as: selectStmt,
      )
        ..setSpan(name, _previous)
        ..asToken = asToken
        ..tableNameToken = name);
    } while (_matchOne(TokenType.comma));

    return WithClause(
      recursive: recursive,
      ctes: ctes,
    )
      ..setSpan(withToken, _previous)
      ..recursiveToken = recursiveToken
      ..withToken = withToken;
  }

  /// Parses a select statement as defined in [the sqlite documentation][s-d],
  /// which means that compound selects and a with clause is supported.
  ///
  /// [s-d]: https://sqlite.org/syntax/select-stmt.html
  BaseSelectStatement? _fullSelect() {
    final clause = _withClause();
    return select(withClause: clause);
  }

  /// Parses a [BaseSelectStatement], which is either a [SelectStatement] or a
  /// [CompoundSelectStatement]. If [noCompound] is set to true, the parser will
  /// only attempt to parse a [SelectStatement].
  ///
  /// This method doesn't parse WITH clauses, most users would probably want to
  /// use [_fullSelect] instead.
  ///
  /// See also:
  /// https://www.sqlite.org/lang_select.html
  BaseSelectStatement? select({bool? noCompound, WithClause? withClause}) {
    if (noCompound == true) {
      return _selectNoCompound(withClause);
    } else {
      final firstTokenOfBase = _peek;
      final first = _selectNoCompound(withClause);

      if (first == null) {
        // _selectNoCompound returns null if there's no select statement at the
        // current position. That's fine if we didn't encounter an with clause
        // already
        if (withClause != null) {
          _error('Expected a SELECT statement to follow the WITH clause here');
        }
        return null;
      }

      final parts = <CompoundSelectPart>[];

      for (;;) {
        final part = _compoundSelectPart();
        if (part != null) {
          parts.add(part);
        } else {
          break;
        }
      }

      if (parts.isEmpty) {
        // no compound parts, just return the simple select statement.
        return first;
      } else {
        // remove with clause from base select, it belongs to the compound
        // select.
        first.withClause = null;
        first.first = firstTokenOfBase;

        return CompoundSelectStatement(
          withClause: withClause,
          base: first,
          additional: parts,
        )..setSpan(withClause?.first ?? first.first!, _previous);
      }
    }
  }

  SelectStatementNoCompound? _selectNoCompound([WithClause? withClause]) {
    if (_peek.type == TokenType.$values) return _valuesSelect(withClause);
    if (!_match(const [TokenType.select])) return null;
    final selectToken = _previous;

    var distinct = false;
    if (_matchOne(TokenType.distinct)) {
      distinct = true;
    } else if (_matchOne(TokenType.all)) {
      distinct = false;
    }

    final resultColumns = <ResultColumn>[];
    do {
      resultColumns.add(_resultColumn());
    } while (_match(const [TokenType.comma]));

    final from = _from();

    final where = _where();
    final groupBy = _groupBy();
    final windowDecls = _windowDeclarations();
    final orderBy = _orderBy();
    final limit = _limit();

    final first = withClause?.first ?? selectToken;
    return SelectStatement(
      withClause: withClause,
      distinct: distinct,
      columns: resultColumns,
      from: from,
      where: where,
      groupBy: groupBy,
      windowDeclarations: windowDecls,
      orderBy: orderBy,
      limit: limit,
    )..setSpan(first, _previous);
  }

  ValuesSelectStatement? _valuesSelect([WithClause? withClause]) {
    if (!_matchOne(TokenType.$values)) return null;
    final firstToken = _previous;

    final tuples = <Tuple>[];
    do {
      tuples.add(_consumeTuple() as Tuple);
    } while (_matchOne(TokenType.comma));

    return ValuesSelectStatement(tuples, withClause: withClause)
      ..setSpan(firstToken, _previous);
  }

  CompoundSelectPart? _compoundSelectPart() {
    if (_match(
        const [TokenType.union, TokenType.intersect, TokenType.except])) {
      final firstModeToken = _previous;
      var mode = const {
        TokenType.union: CompoundSelectMode.union,
        TokenType.intersect: CompoundSelectMode.intersect,
        TokenType.except: CompoundSelectMode.except,
      }[firstModeToken.type];
      Token? allToken;

      if (firstModeToken.type == TokenType.union && _matchOne(TokenType.all)) {
        allToken = _previous;
        mode = CompoundSelectMode.unionAll;
      }

      final select = _selectNoCompound()!;

      return CompoundSelectPart(
        mode: mode!,
        select: select,
      )
        ..firstModeToken = firstModeToken
        ..allToken = allToken
        ..setSpan(firstModeToken, _previous);
    }
    return null;
  }

  /// Parses a [ResultColumn] or throws if none is found.
  /// https://www.sqlite.org/syntax/result-column.html
  ResultColumn _resultColumn() {
    if (_matchOne(TokenType.star)) {
      return StarResultColumn(null)..setSpan(_previous, _previous);
    }

    final positionBefore = _current;

    if (_matchOne(TokenType.identifier)) {
      // two options. the identifier could be followed by ".*", in which case
      // we have a star result column. If it's followed by anything else, it can
      // still refer to a column in a table as part of a expression
      // result column
      final identifier = _previous as IdentifierToken;

      if (_matchOne(TokenType.dot)) {
        if (_matchOne(TokenType.star)) {
          return StarResultColumn(identifier.identifier)
            ..setSpan(identifier, _previous);
        } else if (enableMoorExtensions && _matchOne(TokenType.doubleStar)) {
          return NestedStarResultColumn(identifier.identifier)
            ..setSpan(identifier, _previous);
        }
      }

      // not a star result column. go back and parse the expression.
      // todo this is a bit unorthodox. is there a better way to parse the
      // expression from before?
      _current = positionBefore;
    }

    final tokenBefore = _peek;

    final expr = expression();
    final as = _as();

    return ExpressionResultColumn(expression: expr, as: as?.identifier)
      ..setSpan(tokenBefore, _previous);
  }

  /// Returns an identifier followed after an optional "AS" token in sql.
  /// Returns null if there is
  IdentifierToken? _as() {
    if (_match(const [TokenType.as])) {
      return _consume(TokenType.identifier, 'Expected an identifier')
          as IdentifierToken;
    } else if (_match(const [TokenType.identifier])) {
      return _previous as IdentifierToken;
    } else {
      return null;
    }
  }

  Queryable? _from() {
    if (!_matchOne(TokenType.from)) return null;

    // Can either be a list of <TableOrSubquery> or a join. Joins also start
    // with a TableOrSubquery, so let's first parse that.
    final start = _tableOrSubquery();
    // parse join, if there is one
    return _joinClause(start) ?? start;
  }

  TableOrSubquery _tableOrSubquery() {
    // this is what we're parsing: https://www.sqlite.org/syntax/table-or-subquery.html
    // we currently only support regular tables, table functions and nested
    // selects
    final tableRef = _tableReferenceOrNull();
    if (tableRef != null) {
      // this is a bit hacky. If the table reference only consists of one
      // identifer and it's followed by a (, it's a table-valued function
      if (tableRef.as == null && _matchOne(TokenType.leftParen)) {
        final params = _functionParameters();
        _consume(TokenType.rightParen, 'Expected closing parenthesis');
        final alias = _as();

        return TableValuedFunction(tableRef.tableName, params,
            as: alias?.identifier)
          ..setSpan(tableRef.first!, _previous);
      }

      return tableRef;
    } else if (_matchOne(TokenType.leftParen)) {
      final first = _previous;
      final innerStmt = select()!;
      _consume(TokenType.rightParen,
          'Expected a right bracket to terminate the inner select');

      final alias = _as();
      return SelectStatementAsSource(
          statement: innerStmt, as: alias?.identifier)
        ..setSpan(first, _previous);
    }

    _error('Expected a table name or a nested select statement');
  }

  TableReference? _tableReferenceOrNull() {
    _suggestHint(const TableNameDescription());
    if (_check(TokenType.identifier)) return _tableReference();
    return null;
  }

  TableReference _tableReference() {
    _suggestHint(const TableNameDescription());
    // ignore the schema name, it's not supported. Besides that, we're on the
    // first branch in the diagram here https://www.sqlite.org/syntax/table-or-subquery.html
    final firstToken = _consumeIdentifier('Expected a table reference');

    final tableName = firstToken.identifier;
    final alias = _as();
    return TableReference(tableName, alias?.identifier)
      ..setSpan(firstToken, _previous)
      ..tableNameToken = firstToken;
  }

  JoinClause? _joinClause(TableOrSubquery start) {
    var operator = _parseJoinOperator();
    if (operator == null) {
      return null;
    }

    final joins = <Join>[];

    while (operator != null) {
      final first = _peekNext;

      final subquery = _tableOrSubquery();
      final constraint = _joinConstraint();
      JoinOperator resolvedOperator;
      if (operator.contains(TokenType.left)) {
        resolvedOperator = operator.contains(TokenType.outer)
            ? JoinOperator.leftOuter
            : JoinOperator.left;
      } else if (operator.contains(TokenType.inner)) {
        resolvedOperator = JoinOperator.inner;
      } else if (operator.contains(TokenType.cross)) {
        resolvedOperator = JoinOperator.cross;
      } else if (operator.contains(TokenType.comma)) {
        resolvedOperator = JoinOperator.comma;
      } else {
        resolvedOperator = JoinOperator.none;
      }

      joins.add(Join(
        natural: operator.contains(TokenType.natural),
        operator: resolvedOperator,
        query: subquery,
        constraint: constraint,
      )..setSpan(first, _previous));

      // parse the next operator, if there is more than one join
      operator = _parseJoinOperator();
    }

    return JoinClause(primary: start, joins: joins)
      ..setSpan(start.first!, _previous);
  }

  /// Parses https://www.sqlite.org/syntax/join-operator.html
  List<TokenType>? _parseJoinOperator() {
    const _startJoinOperators = [
      TokenType.natural,
      TokenType.left,
      TokenType.inner,
      TokenType.cross,
      TokenType.join,
      TokenType.comma,
    ];

    if (_match(_startJoinOperators)) {
      final operators = [_previous.type];

      if (_previous.type == TokenType.join ||
          _previous.type == TokenType.comma) {
        // just join or comma, without any specific operators
        return operators;
      } else {
        // natural is a prefix, another operator can follow.
        if (_previous.type == TokenType.natural) {
          if (_match([TokenType.left, TokenType.inner, TokenType.cross])) {
            operators.add(_previous.type);
          }
        }
        if (_previous.type == TokenType.left && _matchOne(TokenType.outer)) {
          operators.add(_previous.type);
        }

        _consume(TokenType.join, 'Expected to see a join keyword here');
        return operators;
      }
    }
    return null;
  }

  /// Parses https://www.sqlite.org/syntax/join-constraint.html
  JoinConstraint? _joinConstraint() {
    if (_matchOne(TokenType.on)) {
      return OnConstraint(expression: expression());
    } else if (_matchOne(TokenType.using)) {
      _consume(TokenType.leftParen, 'Expected an opening paranthesis');

      final columnNames = <String>[];
      do {
        final identifier =
            _consume(TokenType.identifier, 'Expected a column name');
        columnNames.add((identifier as IdentifierToken).identifier);
      } while (_matchOne(TokenType.comma));

      _consume(TokenType.rightParen, 'Expected an closing paranthesis');

      return UsingConstraint(columnNames: columnNames);
    } else {
      return null;
    }
  }

  /// Parses a where clause if there is one at the current position
  Expression? _where() {
    if (_match(const [TokenType.where])) {
      return expression();
    }
    return null;
  }

  GroupBy? _groupBy() {
    if (_matchOne(TokenType.group)) {
      final groupToken = _previous;

      _consume(TokenType.by, 'Expected a "BY"');
      final by = <Expression>[];
      Expression? having;

      do {
        by.add(expression());
      } while (_matchOne(TokenType.comma));

      if (_matchOne(TokenType.having)) {
        having = expression();
      }

      return GroupBy(by: by, having: having)..setSpan(groupToken, _previous);
    }
    return null;
  }

  List<NamedWindowDeclaration> _windowDeclarations() {
    final declarations = <NamedWindowDeclaration>[];
    if (_matchOne(TokenType.window)) {
      do {
        final name = _consumeIdentifier('Expected a name for the window');
        _consume(TokenType.as,
            'Expected AS between the window name and its definition');
        final window = _windowDefinition();

        declarations.add(NamedWindowDeclaration(name.identifier, window));
      } while (_matchOne(TokenType.comma));
    }
    return declarations;
  }

  OrderByBase? _orderBy() {
    if (_matchOne(TokenType.order)) {
      final orderToken = _previous;
      _consume(TokenType.by, 'Expected "BY" after "ORDER" token');
      final terms = <OrderingTermBase>[];
      do {
        terms.add(_orderingTerm());
      } while (_matchOne(TokenType.comma));

      // If we only hit a single ordering term and that term is a Dart
      // placeholder, we can upgrade that term to a full order by placeholder.
      // This gives users more control at runtime (they can specify multiple
      // terms).
      if (terms.length == 1 && terms.single is DartOrderingTermPlaceholder) {
        final termPlaceholder = terms.single as DartOrderingTermPlaceholder;
        return DartOrderByPlaceholder(name: termPlaceholder.name)
          ..setSpan(orderToken, termPlaceholder.last!);
      }

      return OrderBy(terms: terms)..setSpan(orderToken, _previous);
    }
    return null;
  }

  OrderingTermBase _orderingTerm() {
    final expr = expression();
    final mode = _orderingModeOrNull();

    OrderingBehaviorForNulls? nulls;

    if (_matchOne(TokenType.nulls)) {
      if (_matchOne(TokenType.first)) {
        nulls = OrderingBehaviorForNulls.first;
      } else if (_matchOne(TokenType.last)) {
        nulls = OrderingBehaviorForNulls.last;
      } else {
        _error('Expected FIRST or LAST here');
      }
    }

    // if there is nothing (asc/desc, nulls first/last) after a Dart
    // placeholder, we can upgrade the expression to an ordering term
    // placeholder and let users define the mode at runtime.
    if (mode == null && nulls == null && expr is DartExpressionPlaceholder) {
      return DartOrderingTermPlaceholder(name: expr.name)
        ..setSpan(expr.first!, expr.last!);
    }

    return OrderingTerm(expression: expr, orderingMode: mode, nulls: nulls)
      ..setSpan(expr.first!, _previous);
  }

  OrderingMode? _orderingModeOrNull() {
    if (_match(const [TokenType.asc, TokenType.desc])) {
      final mode = _previous.type == TokenType.asc
          ? OrderingMode.ascending
          : OrderingMode.descending;
      return mode;
    }
    return null;
  }

  /// Parses a [Limit] clause, or returns null if there is no limit token after
  /// the current position.
  LimitBase? _limit() {
    if (!_matchOne(TokenType.limit)) return null;

    final limitToken = _previous;

    // Unintuitive, it's "$amount OFFSET $offset", but "$offset, $amount"
    // the order changes between the separator tokens.
    final first = expression();

    if (_matchOne(TokenType.comma)) {
      final separator = _previous;
      final count = expression();
      return Limit(count: count, offsetSeparator: separator, offset: first)
        ..setSpan(limitToken, _previous);
    } else if (_matchOne(TokenType.offset)) {
      final separator = _previous;
      final offset = expression();
      return Limit(count: first, offsetSeparator: separator, offset: offset)
        ..setSpan(limitToken, _previous);
    } else {
      // no offset or comma was parsed (so just LIMIT $expr). In that case, we
      // want to provide additional flexibility to the user by interpreting the
      // expression as a whole limit clause.
      if (first is DartExpressionPlaceholder) {
        return DartLimitPlaceholder(name: first.name)
          ..setSpan(limitToken, _previous);
      }
      return Limit(count: first)..setSpan(limitToken, _previous);
    }
  }

  DeleteStatement? _deleteStmt([WithClause? withClause]) {
    if (!_matchOne(TokenType.delete)) return null;
    final deleteToken = _previous;

    _consume(TokenType.from, 'Expected a FROM here');

    final table = _tableReference();
    Expression? where;

    if (_matchOne(TokenType.where)) {
      where = expression();
    }

    return DeleteStatement(
      withClause: withClause,
      from: table,
      where: where,
    )..setSpan(withClause?.first ?? deleteToken, _previous);
  }

  UpdateStatement? _update([WithClause? withClause]) {
    if (!_matchOne(TokenType.update)) return null;
    final updateToken = _previous;

    FailureMode? failureMode;
    if (_matchOne(TokenType.or)) {
      failureMode = UpdateStatement.failureModeFromToken(_advance().type);
    }

    final table = _tableReference();
    _consume(TokenType.set, 'Expected SET after the table name');

    final set = _setComponents();

    final where = _where();
    return UpdateStatement(
      withClause: withClause,
      or: failureMode,
      table: table,
      set: set,
      where: where,
    )..setSpan(withClause?.first ?? updateToken, _previous);
  }

  List<SetComponent> _setComponents() {
    final set = <SetComponent>[];
    do {
      final columnName =
          _consume(TokenType.identifier, 'Expected a column name to set')
              as IdentifierToken;
      final reference = Reference(columnName: columnName.identifier)
        ..setSpan(columnName, columnName);
      _consume(TokenType.equal, 'Expected = after the column name');
      final expr = expression();

      set.add(SetComponent(column: reference, expression: expr)
        ..setSpan(columnName, _previous));
    } while (_matchOne(TokenType.comma));

    return set;
  }

  InsertStatement? _insertStmt([WithClause? withClause]) {
    if (!_match(const [TokenType.insert, TokenType.replace])) return null;

    final firstToken = _previous;
    InsertMode? insertMode;
    if (_previous.type == TokenType.insert) {
      // insert modes can have a failure clause (INSERT OR xxx)
      if (_matchOne(TokenType.or)) {
        const tokensToModes = {
          TokenType.replace: InsertMode.insertOrReplace,
          TokenType.rollback: InsertMode.insertOrRollback,
          TokenType.abort: InsertMode.insertOrAbort,
          TokenType.fail: InsertMode.insertOrFail,
          TokenType.ignore: InsertMode.insertOrIgnore
        };

        if (_match(tokensToModes.keys)) {
          insertMode = tokensToModes[_previous.type];
        } else {
          _error('After the INSERT OR, expected an insert mode '
              '(REPLACE, ROLLBACK, etc.)');
        }
      } else {
        insertMode = InsertMode.insert;
      }
    } else {
      // if it wasn't an insert, it must have been a replace
      insertMode = InsertMode.replace;
    }
    assert(insertMode != null);
    _consume(TokenType.into, 'Expected INSERT INTO');

    final table = _tableReference();
    final targetColumns = <Reference>[];

    if (_matchOne(TokenType.leftParen)) {
      do {
        final columnRef = _consumeIdentifier('Expected a column');
        targetColumns.add(Reference(columnName: columnRef.identifier)
          ..setSpan(columnRef, columnRef));
      } while (_matchOne(TokenType.comma));

      _consume(TokenType.rightParen,
          'Expected clpsing parenthesis after column list');
    }
    final source = _insertSource();
    final upsert = _upsertClauseOrNull();

    return InsertStatement(
      withClause: withClause,
      mode: insertMode!,
      table: table,
      targetColumns: targetColumns,
      source: source,
      upsert: upsert,
    )..setSpan(withClause?.first ?? firstToken, _previous);
  }

  InsertSource _insertSource() {
    if (_matchOne(TokenType.$values)) {
      final first = _previous;
      final values = <Tuple>[];
      do {
        // it will be a tuple, we don't turn on "orSubQuery"
        values.add(_consumeTuple() as Tuple);
      } while (_matchOne(TokenType.comma));

      return ValuesSource(values)..setSpan(first, _previous);
    } else if (_matchOne(TokenType.$default)) {
      final first = _previous;
      _consume(TokenType.$values, 'Expected DEFAULT VALUES');
      return DefaultValues()..setSpan(first, _previous);
    } else {
      final first = _previous;
      return SelectInsertSource(
        _fullSelect() ?? _error('Expeced a select statement'),
      )..setSpan(first, _previous);
    }
  }

  UpsertClause? _upsertClauseOrNull() {
    if (!_matchOne(TokenType.on)) return null;

    final first = _previous;
    _consume(TokenType.conflict, 'Expected CONFLICT keyword for upsert clause');

    List<IndexedColumn>? indexedColumns;
    Expression? where;
    if (_matchOne(TokenType.leftParen)) {
      indexedColumns = _indexedColumns();

      _consume(TokenType.rightParen, 'Expected closing paren here');
      if (_matchOne(TokenType.where)) {
        where = expression();
      }
    }

    _consume(TokenType.$do,
        'Expected DO, followed by the action (NOTHING or UPDATE SET)');

    late UpsertAction action;
    if (_matchOne(TokenType.nothing)) {
      action = DoNothing()..setSpan(_previous, _previous);
    } else if (_check(TokenType.update)) {
      action = _doUpdate();
    }

    return UpsertClause(
      onColumns: indexedColumns,
      where: where,
      action: action,
    )..setSpan(first, _previous);
  }

  DoUpdate _doUpdate() {
    _consume(TokenType.update, 'Expected UPDATE SET keyword here');
    final first = _previous;
    _consume(TokenType.set, 'Expected UPDATE SET keyword here');

    final set = _setComponents();
    Expression? where;
    if (_matchOne(TokenType.where)) {
      where = expression();
    }

    return DoUpdate(set, where: where)..setSpan(first, _previous);
  }

  /// https://www.sqlite.org/syntax/window-defn.html
  WindowDefinition _windowDefinition() {
    _consume(TokenType.leftParen, 'Expected opening parenthesis');
    final leftParen = _previous;

    String? baseWindowName;
    OrderByBase? orderBy;

    final partitionBy = <Expression>[];
    if (_matchOne(TokenType.identifier)) {
      baseWindowName = (_previous as IdentifierToken).identifier;
    }

    if (_matchOne(TokenType.partition)) {
      _consume(TokenType.by, 'Expected PARTITION BY');
      do {
        partitionBy.add(expression());
      } while (_matchOne(TokenType.comma));
    }

    if (_peek.type == TokenType.order) {
      orderBy = _orderBy();
    }

    final spec = _frameSpec();

    _consume(TokenType.rightParen, 'Expected closing parenthesis');
    return WindowDefinition(
      baseWindowName: baseWindowName,
      partitionBy: partitionBy,
      orderBy: orderBy,
      frameSpec: spec ?? (FrameSpec()..synthetic = true),
    )..setSpan(leftParen, _previous);
  }

  /// https://www.sqlite.org/syntax/frame-spec.html
  FrameSpec? _frameSpec() {
    if (!_match(const [TokenType.range, TokenType.rows, TokenType.groups])) {
      return null;
    }

    final typeToken = _previous;

    final frameType = const {
      TokenType.range: FrameType.range,
      TokenType.rows: FrameType.rows,
      TokenType.groups: FrameType.groups
    }[typeToken.type];

    FrameBoundary start, end;

    // if there is no between token, we just read the start boundary and set the
    // end to currentRow. See the link in the docs
    if (_matchOne(TokenType.between)) {
      start = _frameBoundary(isStartBounds: true, parseExprFollowing: true);
      _consume(TokenType.and, 'Expected AND followed by the ending boundary');
      end = _frameBoundary(isStartBounds: false, parseExprFollowing: true);
    } else {
      // <expr> FOLLOWING is not supported in the short-hand syntax
      start = _frameBoundary(isStartBounds: true, parseExprFollowing: false);
      end = FrameBoundary.currentRow();
    }

    var exclude = ExcludeMode.noOthers;
    if (_matchOne(TokenType.exclude)) {
      if (_matchOne(TokenType.ties)) {
        exclude = ExcludeMode.ties;
      } else if (_matchOne(TokenType.group)) {
        exclude = ExcludeMode.group;
      } else if (_matchOne(TokenType.current)) {
        _consume(TokenType.row, 'Expected EXCLUDE CURRENT ROW');
        exclude = ExcludeMode.currentRow;
      } else if (_matchOne(TokenType.no)) {
        _consume(TokenType.others, 'Expected EXCLUDE NO OTHERS');
        exclude = ExcludeMode.noOthers;
      }
    }

    return FrameSpec(
      type: frameType,
      excludeMode: exclude,
      start: start,
      end: end,
    )..setSpan(typeToken, _previous);
  }

  FrameBoundary _frameBoundary(
      {bool isStartBounds = true, bool parseExprFollowing = true}) {
    // the CURRENT ROW boundary is supported for all modes
    if (_matchOne(TokenType.current)) {
      _consume(TokenType.row, 'Expected ROW to finish CURRENT ROW boundary');
      return FrameBoundary.currentRow();
    }
    if (_matchOne(TokenType.unbounded)) {
      // if this is a start boundary, only UNBOUNDED PRECEDING makes sense.
      // Otherwise, only UNBOUNDED FOLLOWING makes sense
      if (isStartBounds) {
        _consume(TokenType.preceding, 'Expected UNBOUNDED PRECEDING');
        return FrameBoundary.unboundedPreceding();
      } else {
        _consume(TokenType.following, 'Expected UNBOUNDED FOLLOWING');
        return FrameBoundary.unboundedFollowing();
      }
    }

    // ok, not unbounded or CURRENT ROW. It must be <expr> PRECEDING|FOLLOWING
    // then
    final amount = expression();
    if (parseExprFollowing && _matchOne(TokenType.following)) {
      return FrameBoundary.following(amount);
    } else if (_matchOne(TokenType.preceding)) {
      return FrameBoundary.preceding(amount);
    }

    _error('Expected either PRECEDING or FOLLOWING here');
  }

  SchemaStatement? _create() {
    if (!_matchOne(TokenType.create)) return null;

    if (_check(TokenType.table) || _check(TokenType.virtual)) {
      return _createTable();
    } else if (_check(TokenType.trigger)) {
      return _createTrigger();
    } else if (_check(TokenType.unique) || _check(TokenType.$index)) {
      return _createIndex();
    } else if (_check(TokenType.view)) {
      return _createView();
    }

    return null;
  }

  /// Parses a `CREATE TABLE` statement, assuming that the `CREATE` token has
  /// already been matched.
  TableInducingStatement _createTable() {
    final first = _previous;
    assert(first.type == TokenType.create);

    final virtual = _matchOne(TokenType.virtual);

    _consume(TokenType.table, 'Expected TABLE keyword here');

    final ifNotExists = _ifNotExists();

    final tableIdentifier = _consumeIdentifier('Expected a table name');

    if (virtual) {
      return _virtualTable(first, ifNotExists, tableIdentifier);
    }

    // we don't currently support CREATE TABLE x AS SELECT ... statements
    final leftParen = _consume(
        TokenType.leftParen, 'Expected opening parenthesis to list columns');

    final columns = <ColumnDefinition>[];
    final tableConstraints = <TableConstraint>[];
    // the columns must come before the table constraints!
    var encounteredTableConstraint = false;

    do {
      try {
        final tableConstraint = _tableConstraintOrNull();

        if (tableConstraint != null) {
          encounteredTableConstraint = true;
          tableConstraints.add(tableConstraint);
        } else {
          if (encounteredTableConstraint) {
            _error('Expected another table constraint');
          } else {
            columns.add(_columnDefinition());
          }
        }
      } on ParsingError {
        // if we're at the closing bracket, don't try to parse another column
        if (_check(TokenType.rightParen)) break;
        // error while parsing a column definition or table constraint. We try
        // to recover to the next comma.
        _synchronize(TokenType.comma);
        if (_check(TokenType.rightParen)) break;
      }
    } while (_matchOne(TokenType.comma));

    final rightParen =
        _consume(TokenType.rightParen, 'Expected closing parenthesis');

    var withoutRowId = false;
    if (_matchOne(TokenType.without)) {
      _consume(
          TokenType.rowid, 'Expected ROWID to complete the WITHOUT ROWID part');
      withoutRowId = true;
    }

    final overriddenName = _overriddenDataClassName();

    return CreateTableStatement(
      ifNotExists: ifNotExists,
      tableName: tableIdentifier.identifier,
      withoutRowId: withoutRowId,
      columns: columns,
      tableConstraints: tableConstraints,
      overriddenDataClassName: overriddenName,
    )
      ..setSpan(first, _previous)
      ..openingBracket = leftParen
      ..closingBracket = rightParen
      ..tableNameToken = tableIdentifier;
  }

  /// Parses a `CREATE VIRTUAL TABLE` statement, after the `CREATE VIRTUAL TABLE
  /// <name>` tokens have already been read.
  CreateVirtualTableStatement _virtualTable(
      Token first, bool ifNotExists, IdentifierToken nameToken) {
    _consume(TokenType.using, 'Expected USING for virtual table declaration');
    final moduleName = _consumeIdentifier('Expected a module name');
    final args = <SourceSpanWithContext>[];

    if (_matchOne(TokenType.leftParen)) {
      // args can be just about anything, so we accept any token until the right
      // parenthesis closing it of.
      Token? currentStart;
      var levelOfParens = 0;

      void addCurrent() {
        if (currentStart == null) {
          _error('Expected at least one token for the previous argument');
        } else {
          args.add(currentStart!.span.expand(_previous.span));
          currentStart = null;
        }
      }

      for (;;) {
        // begin reading a single argument, which is stopped by a comma or
        // maybe with a ), if the current depth is one
        while (_peek.type != TokenType.rightParen &&
            _peek.type != TokenType.comma) {
          _advance();
          if (_previous.type == TokenType.leftParen) {
            levelOfParens++;
          }
          currentStart ??= _previous;
        }

        // if we just read the last ) of the argument list, finish. Otherwise
        // just handle the ) and continue reading the same argument
        if (_peek.type == TokenType.rightParen) {
          levelOfParens--;
          if (levelOfParens < 0) {
            addCurrent();
            _advance(); // consume the rightParen
            break;
          } else {
            _advance(); // add the rightParen to the current argument
            continue;
          }
        }

        // finished while loop above, but not with a ), so it must be a comma
        // that finishes the current argument
        assert(_peek.type == TokenType.comma);
        addCurrent();
        _advance(); // consume the comma
      }
    }

    final moorDataClassName = _overriddenDataClassName();
    return CreateVirtualTableStatement(
      ifNotExists: ifNotExists,
      tableName: nameToken.identifier,
      moduleName: moduleName.identifier,
      arguments: args,
      overriddenDataClassName: moorDataClassName,
    )
      ..setSpan(first, _previous)
      ..tableNameToken = nameToken
      ..moduleNameToken = moduleName;
  }

  String? _overriddenDataClassName() {
    if (enableMoorExtensions && _matchOne(TokenType.as)) {
      return _consumeIdentifier('Expected the name for the data class')
          .identifier;
    }
    return null;
  }

  /// Parses a "CREATE TRIGGER" statement, assuming that the create token has
  /// already been consumed.
  CreateTriggerStatement? _createTrigger() {
    final create = _previous;
    assert(create.type == TokenType.create);

    if (!_matchOne(TokenType.trigger)) return null;

    final ifNotExists = _ifNotExists();
    final trigger = _consumeIdentifier('Expected a name for the identifier');

    TriggerMode mode;
    if (_matchOne(TokenType.before)) {
      mode = TriggerMode.before;
    } else if (_matchOne(TokenType.after)) {
      mode = TriggerMode.after;
    } else {
      const msg = 'Expected BEFORE, AFTER or INSTEAD OF';
      _consume(TokenType.instead, msg);
      _consume(TokenType.of, msg);
      mode = TriggerMode.insteadOf;
    }

    TriggerTarget target;
    if (_matchOne(TokenType.delete)) {
      target = DeleteTarget()
        ..deleteToken = _previous
        ..setSpan(_previous, _previous);
    } else if (_matchOne(TokenType.insert)) {
      target = InsertTarget()
        ..insertToken = _previous
        ..setSpan(_previous, _previous);
    } else {
      final updateToken = _consume(
          TokenType.update, 'Expected DELETE, INSERT or UPDATE as a trigger');
      final names = <Reference>[];

      if (_matchOne(TokenType.of)) {
        do {
          final name = _consumeIdentifier('Expected column name in ON clause');
          final reference = Reference(columnName: name.identifier)
            ..setSpan(name, name);
          names.add(reference);
        } while (_matchOne(TokenType.comma));
      }

      target = UpdateTarget(names)
        ..updateToken = updateToken
        ..setSpan(updateToken, _previous);
    }

    _consume(TokenType.on, 'Expected ON');
    _suggestHint(const TableNameDescription());
    final nameToken = _consumeIdentifier('Expected a table name');
    final tableRef = TableReference(nameToken.identifier)
      ..setSpan(nameToken, nameToken);

    if (_matchOne(TokenType.$for)) {
      const msg = 'Expected FOR EACH ROW';
      _consume(TokenType.each, msg);
      _consume(TokenType.row, msg);
    }

    Expression? when;
    if (_matchOne(TokenType.when)) {
      when = expression();
    }

    final block = _consumeBlock();

    return CreateTriggerStatement(
      ifNotExists: ifNotExists,
      triggerName: trigger.identifier,
      mode: mode,
      target: target,
      onTable: tableRef,
      when: when,
      action: block,
    )
      ..setSpan(create, _previous)
      ..triggerNameToken = trigger;
  }

  /// Parses a [CreateViewStatement]. The `CREATE` token must have already been
  /// accepted.
  CreateViewStatement? _createView() {
    final create = _previous;
    assert(create.type == TokenType.create);

    if (!_matchOne(TokenType.view)) return null;

    final ifNotExists = _ifNotExists();
    final name = _consumeIdentifier('Expected a name for this view');

    List<String>? columnNames;
    if (_matchOne(TokenType.leftParen)) {
      columnNames = _columnNames();
      _consume(TokenType.rightParen, 'Expected closing bracket');
    }

    _consume(TokenType.as, 'Expected AS SELECT');

    final query = _fullSelect()!;

    return CreateViewStatement(
      ifNotExists: ifNotExists,
      viewName: name.identifier,
      columns: columnNames,
      query: query,
    )
      ..viewNameToken = name
      ..setSpan(create, _previous);
  }

  /// Parses a [CreateIndexStatement]. The `CREATE` token must have already been
  /// accepted.
  CreateIndexStatement? _createIndex() {
    final create = _previous;
    assert(create.type == TokenType.create);

    final unique = _matchOne(TokenType.unique);
    if (!_matchOne(TokenType.$index)) return null;

    final ifNotExists = _ifNotExists();
    final name = _consumeIdentifier('Expected a name for this index');

    _consume(TokenType.on, 'Expected ON table');
    _suggestHint(const TableNameDescription());
    final nameToken = _consumeIdentifier('Expected a table name');
    final tableRef = TableReference(nameToken.identifier)
      ..setSpan(nameToken, nameToken);

    _consume(TokenType.leftParen, 'Expected indexed columns in parentheses');

    final indexes = _indexedColumns();

    _consume(TokenType.rightParen, 'Expected closing bracket');

    Expression? where;
    if (_matchOne(TokenType.where)) {
      where = expression();
    }

    return CreateIndexStatement(
      indexName: name.identifier,
      unique: unique,
      ifNotExists: ifNotExists,
      on: tableRef,
      columns: indexes,
      where: where,
    )
      ..nameToken = name
      ..setSpan(create, _previous);
  }

  List<String> _columnNames() {
    final columns = <String>[];
    do {
      final colName = _consumeIdentifier('Expected a name for this column');

      columns.add(colName.identifier);
    } while (_matchOne(TokenType.comma));

    return columns;
  }

  List<IndexedColumn> _indexedColumns() {
    final indexes = <IndexedColumn>[];
    do {
      final expr = expression();
      final mode = _orderingModeOrNull();

      indexes.add(IndexedColumn(expr, mode)..setSpan(expr.first!, _previous));
    } while (_matchOne(TokenType.comma));

    return indexes;
  }

  /// Parses `IF NOT EXISTS` | epsilon
  bool _ifNotExists() {
    if (_matchOne(TokenType.$if)) {
      _consume(TokenType.not, 'Expected IF to be followed by NOT EXISTS');
      _consume(TokenType.exists, 'Expected IF NOT to be followed by EXISTS');
      return true;
    }
    return false;
  }

  ColumnDefinition _columnDefinition() {
    final name = _consume(TokenType.identifier, 'Expected a column name')
        as IdentifierToken;

    final typeTokens = _typeName();
    String? typeName;

    if (typeTokens != null) {
      typeName = typeTokens.lexeme;
    }

    final constraints = <ColumnConstraint>[];
    ColumnConstraint? constraint;
    while ((constraint = _columnConstraint(orNull: true)) != null) {
      constraints.add(constraint!);
    }

    return ColumnDefinition(
      columnName: name.identifier,
      typeName: typeName,
      constraints: constraints,
    )
      ..setSpan(name, _previous)
      ..typeNames = typeTokens
      ..nameToken = name;
  }

  List<Token>? _typeName() {
    // sqlite doesn't really define what a type name is and has very loose rules
    // at turning them into a type affinity. We support this pattern:
    // typename = identifier [ "(" { identifier | comma | number_literal } ")" ]
    if (!_matchOne(TokenType.identifier)) return null;

    final typeNames = [_previous];

    if (_matchOne(TokenType.leftParen)) {
      typeNames.add(_previous);

      const inBrackets = [
        TokenType.identifier,
        TokenType.comma,
        TokenType.numberLiteral
      ];
      while (_match(inBrackets)) {
        typeNames.add(_previous);
      }

      _consume(TokenType.rightParen,
          'Expected closing parenthesis to finish type name');
      typeNames.add(_previous);
    }

    return typeNames;
  }

  ColumnConstraint? _columnConstraint({bool orNull = false}) {
    final first = _peek;

    final resolvedName = _constraintNameOrNull()?.identifier;

    if (_matchOne(TokenType.primary)) {
      _suggestHint(HintDescription.token(TokenType.key));
      _consume(TokenType.key, 'Expected KEY to complete PRIMARY KEY clause');

      final mode = _orderingModeOrNull();
      final conflict = _conflictClauseOrNull();

      _suggestHint(HintDescription.token(TokenType.autoincrement));
      final hasAutoInc = _matchOne(TokenType.autoincrement);

      return PrimaryKeyColumn(resolvedName,
          autoIncrement: hasAutoInc, mode: mode, onConflict: conflict)
        ..setSpan(first, _previous);
    }
    if (_matchOne(TokenType.$null)) {
      final nullToken = _previous;
      return NullColumnConstraint(resolvedName, $null: nullToken)
        ..setSpan(nullToken, nullToken);
    }
    if (_matchOne(TokenType.not)) {
      _suggestHint(HintDescription.token(TokenType.$null));

      final notToken = _previous;
      final nullToken =
          _consume(TokenType.$null, 'Expected NULL to complete NOT NULL');

      return NotNull(resolvedName, onConflict: _conflictClauseOrNull())
        ..setSpan(first, _previous)
        ..not = notToken
        ..$null = nullToken;
    }
    if (_matchOne(TokenType.unique)) {
      return UniqueColumn(resolvedName, _conflictClauseOrNull())
        ..setSpan(first, _previous);
    }
    if (_matchOne(TokenType.check)) {
      final expr = _expressionInParentheses();
      return CheckColumn(resolvedName, expr)..setSpan(first, _previous);
    }
    if (_matchOne(TokenType.$default)) {
      Expression? expr = _literalOrNull();

      // when not a literal, expect an expression in parentheses
      expr ??= _expressionInParentheses();

      return Default(resolvedName, expr)..setSpan(first, _previous);
    }
    if (_matchOne(TokenType.collate)) {
      final collation = _consumeIdentifier('Expected the collation name');

      return CollateConstraint(resolvedName, collation.identifier)
        ..setSpan(first, _previous);
    }
    if (_peek.type == TokenType.references) {
      final clause = _foreignKeyClause();
      return ForeignKeyColumnConstraint(resolvedName, clause)
        ..setSpan(first, _previous);
    }
    if (enableMoorExtensions && _matchOne(TokenType.mapped)) {
      _consume(TokenType.by, 'Expected a MAPPED BY constraint');

      final dartExpr = _consume(
          TokenType.inlineDart, 'Expected Dart expression in backticks');

      return MappedBy(resolvedName, dartExpr as InlineDartToken)
        ..setSpan(first, _previous);
    }
    if (enableMoorExtensions && _matchOne(TokenType.json)) {
      final jsonToken = _previous;
      final keyToken =
          _consume(TokenType.key, 'Expected a JSON KEY constraint');
      final name = _consumeIdentifier('Expected a name for for the json key');

      return JsonKey(resolvedName, name)
        ..setSpan(first, _previous)
        ..json = jsonToken
        ..key = keyToken;
    }
    if (enableMoorExtensions && _matchOne(TokenType.as)) {
      final asToken = _previous;
      final nameToken = _consumeIdentifier('Expected Dart getter name');

      return MoorDartName(resolvedName, nameToken)
        ..setSpan(first, _previous)
        ..as = asToken;
    }

    // no known column constraint matched. If orNull is set and we're not
    // guaranteed to be in a constraint clause (started with CONSTRAINT), we
    // can return null
    if (orNull && resolvedName == null) {
      return null;
    }
    _error('Expected a constraint (primary key, nullability, etc.)');
  }

  TableConstraint? _tableConstraintOrNull() {
    final first = _peek;
    final nameToken = _constraintNameOrNull();
    final name = nameToken?.identifier;

    TableConstraint? result;
    if (_match([TokenType.unique, TokenType.primary])) {
      final isPrimaryKey = _previous.type == TokenType.primary;

      if (isPrimaryKey) {
        _consume(TokenType.key, 'Expected KEY to start PRIMARY KEY clause');
      }

      _consume(TokenType.leftParen,
          'Expected a left parenthesis to start key columns');
      final columns = _indexedColumns();
      _consume(
          TokenType.rightParen, 'Expected a closing parenthesis after columns');
      final conflictClause = _conflictClauseOrNull();

      result = KeyClause(name,
          isPrimaryKey: isPrimaryKey,
          columns: columns,
          onConflict: conflictClause);
    } else if (_matchOne(TokenType.check)) {
      final expr = _expressionInParentheses();
      result = CheckTable(name, expr);
    } else if (_matchOne(TokenType.foreign)) {
      _consume(TokenType.key, 'Expected KEY to start FOREIGN KEY clause');
      final columns = _listColumnsInParentheses(allowEmpty: false);
      final clause = _foreignKeyClause();

      result =
          ForeignKeyTableConstraint(name, columns: columns, clause: clause);
    }

    if (result != null) {
      result
        ..setSpan(first, _previous)
        ..nameToken = nameToken;
      return result;
    }

    if (name != null) {
      // if a constraint was started with CONSTRAINT <name> but then we didn't
      // find a constraint, that's an syntax error
      _error('Expected a table constraint (e.g. a primary key)');
    }
    return null;
  }

  IdentifierToken? _constraintNameOrNull() {
    if (_matchOne(TokenType.constraint)) {
      final name = _consumeIdentifier('Expect a name for the constraint here');
      return name;
    }
    return null;
  }

  Expression _expressionInParentheses() {
    _consume(TokenType.leftParen, 'Expected opening parenthesis');
    final expr = expression();
    _consume(TokenType.rightParen, 'Expected closing parenthesis');
    return expr;
  }

  ConflictClause? _conflictClauseOrNull() {
    _suggestHint(HintDescription.token(TokenType.on));
    if (_matchOne(TokenType.on)) {
      _consume(TokenType.conflict,
          'Expected CONFLICT to complete ON CONFLICT clause');

      const modes = {
        TokenType.rollback: ConflictClause.rollback,
        TokenType.abort: ConflictClause.abort,
        TokenType.fail: ConflictClause.fail,
        TokenType.ignore: ConflictClause.ignore,
        TokenType.replace: ConflictClause.replace,
      };
      _suggestHint(HintDescription.tokens(modes.keys.toList()));

      if (_match(modes.keys)) {
        return modes[_previous.type];
      } else {
        _error('Expected a conflict handler (rollback, abort, etc.) here');
      }
    }

    return null;
  }

  ForeignKeyClause _foreignKeyClause() {
    // https://www.sqlite.org/syntax/foreign-key-clause.html
    _consume(TokenType.references, 'Expected REFERENCES');
    final firstToken = _previous;

    final foreignTable = _consumeIdentifier('Expected a table name');
    final foreignTableName = TableReference(foreignTable.identifier, null)
      ..setSpan(foreignTable, foreignTable);

    final columnNames = _listColumnsInParentheses(allowEmpty: true);

    ReferenceAction? onDelete, onUpdate;

    _suggestHint(HintDescription.token(TokenType.on));
    while (_matchOne(TokenType.on)) {
      _suggestHint(
          const HintDescription.tokens([TokenType.delete, TokenType.update]));
      if (_matchOne(TokenType.delete)) {
        onDelete = _referenceAction();
      } else if (_matchOne(TokenType.update)) {
        onUpdate = _referenceAction();
      } else {
        _error('Expected either DELETE or UPDATE');
      }
    }

    DeferrableClause? deferrable;
    if (_checkWithNot(TokenType.deferrable)) {
      final first = _peekNext;

      final not = _matchOne(TokenType.not);
      _consume(TokenType.deferrable);

      InitialDeferrableMode? mode;
      if (_matchOne(TokenType.initially)) {
        if (_matchOne(TokenType.deferred)) {
          mode = InitialDeferrableMode.deferred;
        } else if (_matchOne(TokenType.immediate)) {
          mode = InitialDeferrableMode.immediate;
        } else {
          _error('Expected DEFERRED or IMMEDIATE here');
        }
      }

      deferrable = DeferrableClause(not, mode)..setSpan(first, _previous);
    }

    return ForeignKeyClause(
      foreignTable: foreignTableName,
      columnNames: columnNames,
      onUpdate: onUpdate,
      onDelete: onDelete,
      deferrable: deferrable,
    )..setSpan(firstToken, _previous);
  }

  ReferenceAction _referenceAction() {
    if (_matchOne(TokenType.cascade)) {
      return ReferenceAction.cascade;
    } else if (_matchOne(TokenType.restrict)) {
      return ReferenceAction.restrict;
    } else if (_matchOne(TokenType.no)) {
      _consume(TokenType.action, 'Expect ACTION to complete NO ACTION clause');
      return ReferenceAction.noAction;
    } else if (_matchOne(TokenType.set)) {
      if (_matchOne(TokenType.$null)) {
        return ReferenceAction.setNull;
      } else if (_matchOne(TokenType.$default)) {
        return ReferenceAction.setDefault;
      } else {
        _error('Expected either NULL or DEFAULT as set action here');
      }
    } else {
      _error('Not a valid action, expected CASCADE, SET NULL, etc..');
    }
  }

  List<Reference> _listColumnsInParentheses({bool allowEmpty = false}) {
    final columnNames = <Reference>[];
    if (_matchOne(TokenType.leftParen)) {
      do {
        final referenceId = _consumeIdentifier('Expected a column name');
        final reference = Reference(columnName: referenceId.identifier)
          ..setSpan(referenceId, referenceId);
        columnNames.add(reference);
      } while (_matchOne(TokenType.comma));

      _consume(TokenType.rightParen,
          'Expected closing paranthesis after column names');
    } else {
      if (!allowEmpty) {
        _error('Expected a list of columns in parantheses');
      }
    }

    return columnNames;
  }
}

extension on List<Token> {
  String get lexeme => first.span.expand(last.span).text;
}
