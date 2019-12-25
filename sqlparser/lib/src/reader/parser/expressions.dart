part of 'parser.dart';

/// Parses expressions. Expressions have the following precedence:
/// - `-`, `+`, `~`, unary not
/// - `||` (concatenation)
/// - `*`, '/', '%'
/// - `+`, `-`
/// - `<<`, `>>`, `&`, `|`
/// - `<`, `<=`, `>`, `>=`
/// - `=`, `==`, `!=`, `<>`, `IS`, `IS NOT`, `IN`, `LIKE`, `GLOB`, `MATCH`,
///   `REGEXP`
/// - `AND`
/// - `OR`
/// - Case expressions
mixin ExpressionParser on ParserBase {
  @override
  Expression expression() {
    return _case();
  }

  Expression _case() {
    if (_matchOne(TokenType.$case)) {
      final caseToken = _previous;

      final base = _check(TokenType.when) ? null : _or();
      final whens = <WhenComponent>[];
      Expression $else;

      while (_matchOne(TokenType.when)) {
        final whenToken = _previous;

        final whenExpr = _or();
        _consume(TokenType.then, 'Expected THEN');
        final then = _or();
        whens.add(WhenComponent(when: whenExpr, then: then)
          ..setSpan(whenToken, _previous));
      }

      if (_matchOne(TokenType.$else)) {
        $else = _or();
      }

      _consume(TokenType.end, 'Expected END to finish the case operator');
      return CaseExpression(whens: whens, base: base, elseExpr: $else)
        ..setSpan(caseToken, _previous);
    }

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
        ..setSpan(expression.first, _previous);
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
        ..setSpan(left.first, _previous);
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
          ..setSpan(first, _previous);
      } else if (_match(ops)) {
        final operator = _previous;
        if (operator.type == TokenType.$is) {
          final not = _match(const [TokenType.not]);
          // special case: is not expression
          expression = IsExpression(not, expression, _comparison())
            ..setSpan(first, _previous);
        } else {
          expression = BinaryExpression(expression, operator, _comparison())
            ..setSpan(first, _previous);
        }
      } else if (_checkAnyWithNot(stringOps)) {
        final not = _matchOne(TokenType.not);
        _match(stringOps); // will consume, existence was verified with check
        final operator = _previous;

        final right = _comparison();
        Expression escape;
        if (_matchOne(TokenType.escape)) {
          escape = _comparison();
        }

        expression = StringComparisonExpression(
            not: not,
            left: expression,
            operator: operator,
            right: right,
            escape: escape)
          ..setSpan(first, _previous);
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
        ..setSpan(operator, expression.last);
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
    // todo parse ISNULL, NOTNULL, NOT NULL, etc.
    // I don't even know the precedence ¯\_(ツ)_/¯ (probably not higher than
    // unary)
    var expression = _primary();

    while (_matchOne(TokenType.collate)) {
      final collateOp = _previous;
      final collateFun =
          _consume(TokenType.identifier, 'Expected a collating sequence')
              as IdentifierToken;
      expression = CollateExpression(
        inner: expression,
        operator: collateOp,
        collateFunction: collateFun,
      )..setSpan(expression.first, collateFun);
    }

    return expression;
  }

  @override
  Literal _literalOrNull() {
    final token = _peek;

    Literal _parseInner() {
      if (_matchOne(TokenType.numberLiteral)) {
        return NumericLiteral(_parseNumber(token.lexeme), token);
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
      // todo CURRENT_TIME, CURRENT_DATE, CURRENT_TIMESTAMP
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

    _error('Could not parse this expression');
  }

  @override
  Variable _variableOrNull() {
    if (_matchOne(TokenType.questionMarkVariable)) {
      return NumberedVariable(_previous as QuestionMarkVariableToken)
        ..setSpan(_previous, _previous);
    } else if (_matchOne(TokenType.colonVariable)) {
      return ColonNamedVariable(_previous as ColonVariableToken)
        ..setSpan(_previous, _previous);
    }
    return null;
  }

  FunctionParameters _functionParameters() {
    if (_matchOne(TokenType.star)) {
      return const StarFunctionParameter();
    }

    if (_check(TokenType.rightParen)) {
      // nothing between the brackets -> empty parameter list
      return ExprFunctionParameters(parameters: const []);
    }

    final distinct = _matchOne(TokenType.distinct);
    final parameters = <Expression>[];

    do {
      parameters.add(expression());
    } while (_matchOne(TokenType.comma));

    return ExprFunctionParameters(distinct: distinct, parameters: parameters);
  }

  AggregateExpression _aggregate(
      IdentifierToken name, FunctionParameters params) {
    Expression filter;

    // https://www.sqlite.org/syntax/filter.html (it's optional)
    if (_matchOne(TokenType.filter)) {
      _consume(TokenType.leftParen,
          'Expected opening parenthesis after filter statement');
      _consume(TokenType.where, 'Expected WHERE clause');
      filter = expression();
      _consume(TokenType.rightParen, 'Expecteded closing parenthes');
    }

    _consume(TokenType.over, 'Expected OVER to begin window clause');

    String windowName;
    WindowDefinition window;

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

  @override
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
}
