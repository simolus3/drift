import 'package:meta/meta.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

part 'num_parser.dart';

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

// todo better error handling and synchronisation, like it's done here:
// https://craftinginterpreters.com/parsing-expressions.html#synchronizing-a-recursive-descent-parser

class Parser {
  final List<Token> tokens;
  final List<ParsingError> errors = [];
  int _current = 0;

  Parser(this.tokens);

  bool get _isAtEnd => _peek.type == TokenType.eof;
  Token get _peek => tokens[_current];
  Token get _peekNext => tokens[_current + 1];
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

  Statement statement() {
    final stmt = select() ?? _deleteStmt() ?? _update();

    _matchOne(TokenType.semicolon);
    return stmt;
  }

  /// Parses a [SelectStatement], or returns null if there is no select token
  /// after the current position.
  ///
  /// See also:
  /// https://www.sqlite.org/lang_select.html
  SelectStatement select() {
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
    final orderBy = _orderBy();
    final limit = _limit();

    return SelectStatement(
      distinct: distinct,
      columns: resultColumns,
      from: from,
      where: where,
      groupBy: groupBy,
      orderBy: orderBy,
      limit: limit,
    )..setSpan(selectToken, _previous);
  }

  /// Parses a [ResultColumn] or throws if none is found.
  /// https://www.sqlite.org/syntax/result-column.html
  ResultColumn _resultColumn() {
    if (_match(const [TokenType.star])) {
      return StarResultColumn(null)..setSpan(_previous, _previous);
    }

    final positionBefore = _current;

    if (_match(const [TokenType.identifier])) {
      // two options. the identifier could be followed by ".*", in which case
      // we have a star result column. If it's followed by anything else, it can
      // still refer to a column in a table as part of a expression result column
      final identifier = _previous;

      if (_match(const [TokenType.dot]) && _match(const [TokenType.star])) {
        return StarResultColumn((identifier as IdentifierToken).identifier)
          ..setSpan(identifier, _previous);
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
  IdentifierToken _as() {
    if (_match(const [TokenType.as])) {
      return _consume(TokenType.identifier, 'Expected an identifier')
          as IdentifierToken;
    } else if (_match(const [TokenType.identifier])) {
      return _previous as IdentifierToken;
    } else {
      return null;
    }
  }

  List<Queryable> _from() {
    if (!_matchOne(TokenType.from)) return [];

    // Can either be a list of <TableOrSubquery> or a join. Joins also start
    // with a TableOrSubquery, so let's first parse that.
    final start = _tableOrSubquery();
    // parse join, if it is one
    final join = _joinClause(start);
    if (join != null) {
      return [join];
    }

    // not a join. Keep the TableOrSubqueries coming!
    final queries = [start];
    while (_matchOne(TokenType.comma)) {
      queries.add(_tableOrSubquery());
    }

    return queries;
  }

  TableOrSubquery _tableOrSubquery() {
    //  this is what we're parsing: https://www.sqlite.org/syntax/table-or-subquery.html
    // we currently only support regular tables and nested selects
    final tableRef = _tableReference();
    if (tableRef != null) {
      return tableRef;
    } else if (_matchOne(TokenType.leftParen)) {
      final innerStmt = select();
      _consume(TokenType.rightParen,
          'Expected a right bracket to terminate the inner select');

      final alias = _as();
      return SelectStatementAsSource(
          statement: innerStmt, as: alias?.identifier);
    }

    _error('Expected a table name or a nested select statement');
  }

  TableReference _tableReference() {
    if (_matchOne(TokenType.identifier)) {
      // ignore the schema name, it's not supported. Besides that, we're on the
      // first branch in the diagram here
      final tableName = (_previous as IdentifierToken).identifier;
      final alias = _as();
      return TableReference(tableName, alias?.identifier);
    }
    return null;
  }

  JoinClause _joinClause(TableOrSubquery start) {
    var operator = _parseJoinOperatorNoComma();
    if (operator == null) {
      return null;
    }

    final joins = <Join>[];

    while (operator != null) {
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
      ));

      // parse the next operator, if there is more than one join
      if (_matchOne(TokenType.comma)) {
        operator = [TokenType.comma];
      } else {
        operator = _parseJoinOperatorNoComma();
      }
    }

    return JoinClause(primary: start, joins: joins);
  }

  /// Parses https://www.sqlite.org/syntax/join-operator.html, minus the comma.
  List<TokenType> _parseJoinOperatorNoComma() {
    if (_match(_startOperators)) {
      final operators = [_previous.type];

      if (_previous.type == TokenType.join) {
        // just join, without any specific operators
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
  JoinConstraint _joinConstraint() {
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
    }
    _error('Expected a constraint with ON or USING');
  }

  /// Parses a where clause if there is one at the current position
  Expression _where() {
    if (_match(const [TokenType.where])) {
      return expression();
    }
    return null;
  }

  GroupBy _groupBy() {
    if (_matchOne(TokenType.group)) {
      _consume(TokenType.by, 'Expected a "BY"');
      final by = <Expression>[];
      Expression having;

      do {
        by.add(expression());
      } while (_matchOne(TokenType.comma));

      if (_matchOne(TokenType.having)) {
        having = expression();
      }

      return GroupBy(by: by, having: having);
    }
    return null;
  }

  OrderBy _orderBy() {
    if (_match(const [TokenType.order])) {
      _consume(TokenType.by, 'Expected "BY" after "ORDER" token');
      final terms = <OrderingTerm>[];
      do {
        terms.add(_orderingTerm());
      } while (_matchOne(TokenType.comma));
      return OrderBy(terms: terms);
    }
    return null;
  }

  OrderingTerm _orderingTerm() {
    final expr = expression();

    if (_match(const [TokenType.asc, TokenType.desc])) {
      final mode = _previous.type == TokenType.asc
          ? OrderingMode.ascending
          : OrderingMode.descending;
      return OrderingTerm(expression: expr, orderingMode: mode);
    }

    return OrderingTerm(expression: expr);
  }

  /// Parses a [Limit] clause, or returns null if there is no limit token after
  /// the current position.
  Limit _limit() {
    if (!_matchOne(TokenType.limit)) return null;

    final count = expression();
    Token offsetSep;
    Expression offset;

    if (_match(const [TokenType.comma, TokenType.offset])) {
      offsetSep = _previous;
      offset = expression();
    }

    return Limit(count: count, offsetSeparator: offsetSep, offset: offset);
  }

  DeleteStatement _deleteStmt() {
    if (!_matchOne(TokenType.delete)) return null;
    _consume(TokenType.from, 'Expected a FROM here');

    final table = _tableReference();
    Expression where;
    if (table == null) {
      _error('Expected a table reference');
    }

    if (_matchOne(TokenType.where)) {
      where = expression();
    }

    return DeleteStatement(from: table, where: where);
  }

  UpdateStatement _update() {
    if (!_matchOne(TokenType.update)) return null;
    FailureMode failureMode;
    if (_matchOne(TokenType.or)) {
      failureMode = UpdateStatement.failureModeFromToken(_advance().type);
    }

    final table = _tableReference();
    _consume(TokenType.set, 'Expected SET after the table name');

    final set = <SetComponent>[];
    do {
      final reference = _primary() as Reference;
      _consume(TokenType.equal, 'Expected = after the column name');
      final expr = expression();

      set.add(SetComponent(column: reference, expression: expr));
    } while (_matchOne(TokenType.comma));

    final where = _where();
    return UpdateStatement(
        or: failureMode, table: table, set: set, where: where);
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
    return _case();
  }

  Expression _case() {
    if (_matchOne(TokenType.$case)) {
      final base = _check(TokenType.when) ? null : _or();
      final whens = <WhenComponent>[];
      Expression $else;

      while (_matchOne(TokenType.when)) {
        final whenExpr = _or();
        _consume(TokenType.then, 'Expected THEN');
        final then = _or();
        whens.add(WhenComponent(when: whenExpr, then: then));
      }

      if (_matchOne(TokenType.$else)) {
        $else = _or();
      }

      _consume(TokenType.end, 'Expected END to finish the case operator');
      return CaseExpression(whens: whens, base: base, elseExpr: $else);
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
      expression = BinaryExpression(expression, operator, right);
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

      var inside = _equals();
      if (inside is Parentheses) {
        // if we have something like x IN (3), then (3) is a tuple and not a
        // parenthesis. We can only know this from the context unfortunately
        inside = (inside as Parentheses).asTuple;
      }

      return InExpression(left: left, inside: inside, not: not);
    }

    return left;
  }

  /// Parses expressions with the "equals" precedence. This contains
  /// comparisons, "IS (NOT) IN" expressions, between expressions and "like"
  /// expressions.
  Expression _equals() {
    var expression = _comparison();

    final ops = const [
      TokenType.equal,
      TokenType.doubleEqual,
      TokenType.exclamationEqual,
      TokenType.lessMore,
      TokenType.$is,
    ];
    final stringOps = const [
      TokenType.like,
      TokenType.glob,
      TokenType.match,
      TokenType.regexp,
    ];

    while (true) {
      if (_checkWithNot(TokenType.between)) {
        final not = _matchOne(TokenType.not);
        _consume(TokenType.between, 'expected a BETWEEN');

        final lower = _comparison();
        _consume(TokenType.and, 'expected AND');
        final upper = _comparison();

        expression = BetweenExpression(
            not: not, check: expression, lower: lower, upper: upper);
      } else if (_match(ops)) {
        final operator = _previous;
        if (operator.type == TokenType.$is) {
          final not = _match(const [TokenType.not]);
          // special case: is not expression
          expression = IsExpression(not, expression, _comparison());
        } else {
          expression = BinaryExpression(expression, operator, _comparison());
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
            escape: escape);
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
      TokenType.not
    ])) {
      final operator = _previous;
      final expression = _unary();
      return UnaryExpression(operator, expression);
    } else if (_matchOne(TokenType.exists)) {
      _consume(
          TokenType.leftParen, 'Expected opening parenthesis after EXISTS');
      final selectStmt = select();
      _consume(TokenType.rightParen,
          'Expected closing paranthesis to finish EXISTS expression');
      return ExistsExpression(select: selectStmt);
    }

    return _postfix();
  }

  Expression _postfix() {
    // todo parse ISNULL, NOTNULL, NOT NULL, etc.
    // I don't even know the precedence ¯\_(ツ)_/¯ (probably not higher than
    // unary)
    return _primary();
  }

  Expression _primary() {
    final token = _advance();
    final type = token.type;
    switch (type) {
      case TokenType.numberLiteral:
        return NumericLiteral(_parseNumber(token.lexeme), token);
      case TokenType.stringLiteral:
        return StringLiteral(token as StringLiteralToken);
      case TokenType.$null:
        return NullLiteral(token);
      case TokenType.$true:
        return BooleanLiteral.withTrue(token);
      case TokenType.$false:
        return BooleanLiteral.withFalse(token);
      // todo CURRENT_TIME, CURRENT_DATE, CURRENT_TIMESTAMP
      case TokenType.leftParen:
        // Opening brackets could be three things: An inner select statement
        // (SELECT ...), a parenthesised expression, or a tuple of expressions
        // (a, b, c).
        final left = token;
        if (_peek.type == TokenType.select) {
          final stmt = select();
          _consume(TokenType.rightParen, 'Expected a closing bracket');
          return SubQuery(select: stmt);
        } else {
          final expr = expression();

          // Are we witnessing a tuple?
          if (_check(TokenType.comma)) {
            // we are, add expressions as long as we see commas
            final exprs = [expr];
            while (_matchOne(TokenType.comma)) {
              exprs.add(expression());
            }

            _consume(TokenType.rightParen, 'Expected a closing bracket');
            return TupleExpression(expressions: exprs);
          } else {
            // we aren't, so that'll just be parentheses.
            _consume(TokenType.rightParen, 'Expected a closing bracket');
            return Parentheses(left, expr, token);
          }
        }
        break;
      case TokenType.identifier:
        // could be table.column, function(...) or just column
        final first = token as IdentifierToken;

        if (_matchOne(TokenType.dot)) {
          final second =
              _consume(TokenType.identifier, 'Expected a column name here')
                  as IdentifierToken;
          return Reference(
              tableName: first.identifier, columnName: second.identifier)
            ..setSpan(first, second);
        } else if (_matchOne(TokenType.leftParen)) {
          final parameters = _functionParameters();
          final rightParen = _consume(TokenType.rightParen,
              'Expected closing bracket after argument list');

          return FunctionExpression(
              name: first.identifier, parameters: parameters)
            ..setSpan(first, rightParen);
        } else {
          return Reference(columnName: first.identifier)..setSpan(first, first);
        }
        break;
      case TokenType.questionMark:
        final mark = token;

        if (_matchOne(TokenType.numberLiteral)) {
          final number = _previous;
          return NumberedVariable(mark, _parseNumber(number.lexeme).toInt())
            ..setSpan(mark, number);
        } else {
          return NumberedVariable(mark, null)..setSpan(mark, mark);
        }
        break;
      case TokenType.colon:
        final colon = token;
        final identifier = _consume(TokenType.identifier,
            'Expected an identifier for the named variable') as IdentifierToken;
        final content = identifier.identifier;
        return ColonNamedVariable(':$content')..setSpan(colon, identifier);
      default:
        break;
    }

    // nothing found -> issue error
    _error('Could not parse this expression');
  }

  FunctionParameters _functionParameters() {
    if (_matchOne(TokenType.star)) {
      return const StarFunctionParameter();
    }

    final distinct = _matchOne(TokenType.distinct);
    final parameters = <Expression>[];
    while (_peek.type != TokenType.rightParen) {
      parameters.add(expression());
    }
    return ExprFunctionParameters(distinct: distinct, parameters: parameters);
  }
}
