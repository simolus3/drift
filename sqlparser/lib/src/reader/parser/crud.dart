part of 'parser.dart';

const _startJoinOperators = [
  TokenType.natural,
  TokenType.left,
  TokenType.inner,
  TokenType.cross,
  TokenType.join,
  TokenType.comma,
];

mixin CrudParser on ParserBase {
  CrudStatement _crud() {
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

  WithClause _withClause() {
    if (!_matchOne(TokenType.$with)) return null;
    final withToken = _previous;

    final recursive = _matchOne(TokenType.recursive);
    final recursiveToken = recursive ? _previous : null;

    final ctes = <CommonTableExpression>[];
    do {
      final name = _consumeIdentifier('Expected name for common table');
      List<String> columnNames;

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

  @override
  BaseSelectStatement _fullSelect() {
    final clause = _withClause();
    return select(withClause: clause);
  }

  @override
  BaseSelectStatement select({bool noCompound, WithClause withClause}) {
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
        )..setSpan(withClause?.first ?? first.first, _previous);
      }
    }
  }

  SelectStatementNoCompound _selectNoCompound([WithClause withClause]) {
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

  ValuesSelectStatement _valuesSelect([WithClause withClause]) {
    if (!_matchOne(TokenType.$values)) return null;
    final firstToken = _previous;

    final tuples = <Tuple>[];
    do {
      tuples.add(_consumeTuple() as Tuple);
    } while (_matchOne(TokenType.comma));

    return ValuesSelectStatement(tuples, withClause: withClause)
      ..setSpan(firstToken, _previous);
  }

  CompoundSelectPart _compoundSelectPart() {
    if (_match(
        const [TokenType.union, TokenType.intersect, TokenType.except])) {
      final firstModeToken = _previous;
      var mode = const {
        TokenType.union: CompoundSelectMode.union,
        TokenType.intersect: CompoundSelectMode.intersect,
        TokenType.except: CompoundSelectMode.except,
      }[firstModeToken.type];
      Token allToken;

      if (firstModeToken.type == TokenType.union && _matchOne(TokenType.all)) {
        allToken = _previous;
        mode = CompoundSelectMode.unionAll;
      }

      final select = _selectNoCompound();

      return CompoundSelectPart(
        mode: mode,
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

  Queryable /*?*/ _from() {
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
    final tableRef = _tableReference();
    if (tableRef != null) {
      // this is a bit hacky. If the table reference only consists of one
      // identifer and it's followed by a (, it's a table-valued function
      if (tableRef.as == null && _matchOne(TokenType.leftParen)) {
        final params = _functionParameters();
        _consume(TokenType.rightParen, 'Expected closing parenthesis');
        final alias = _as();

        return TableValuedFunction(tableRef.tableName, params,
            as: alias?.identifier)
          ..setSpan(tableRef.first, _previous);
      }

      return tableRef;
    } else if (_matchOne(TokenType.leftParen)) {
      final first = _previous;
      final innerStmt = select();
      _consume(TokenType.rightParen,
          'Expected a right bracket to terminate the inner select');

      final alias = _as();
      return SelectStatementAsSource(
          statement: innerStmt, as: alias?.identifier)
        ..setSpan(first, _previous);
    }

    _error('Expected a table name or a nested select statement');
  }

  TableReference _tableReference() {
    _suggestHint(const TableNameDescription());
    if (_matchOne(TokenType.identifier)) {
      // ignore the schema name, it's not supported. Besides that, we're on the
      // first branch in the diagram here https://www.sqlite.org/syntax/table-or-subquery.html
      final firstToken = _previous as IdentifierToken;
      final tableName = firstToken.identifier;
      final alias = _as();
      return TableReference(tableName, alias?.identifier)
        ..setSpan(firstToken, _previous)
        ..tableNameToken = firstToken;
    }
    return null;
  }

  JoinClause _joinClause(TableOrSubquery start) {
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
      ..setSpan(start.first, _previous);
  }

  /// Parses https://www.sqlite.org/syntax/join-operator.html
  List<TokenType> _parseJoinOperator() {
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
  JoinConstraint /*?*/ _joinConstraint() {
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
  Expression _where() {
    if (_match(const [TokenType.where])) {
      return expression();
    }
    return null;
  }

  GroupBy _groupBy() {
    if (_matchOne(TokenType.group)) {
      final groupToken = _previous;

      _consume(TokenType.by, 'Expected a "BY"');
      final by = <Expression>[];
      Expression having;

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

  OrderByBase _orderBy() {
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
          ..setSpan(termPlaceholder.first, termPlaceholder.last);
      }

      return OrderBy(terms: terms)..setSpan(orderToken, _previous);
    }
    return null;
  }

  OrderingTermBase _orderingTerm() {
    final expr = expression();
    final mode = _orderingModeOrNull();

    // if there is no ASC or DESC after a Dart placeholder, we can upgrade the
    // expression to an ordering term placeholder and let users define the mode
    // at runtime.
    if (mode == null && expr is DartExpressionPlaceholder) {
      return DartOrderingTermPlaceholder(name: expr.name)
        ..setSpan(expr.first, expr.last);
    }

    return OrderingTerm(expression: expr, orderingMode: mode)
      ..setSpan(expr.first, _previous);
  }

  @override
  OrderingMode _orderingModeOrNull() {
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
  LimitBase _limit() {
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

  DeleteStatement _deleteStmt([WithClause withClause]) {
    if (!_matchOne(TokenType.delete)) return null;
    final deleteToken = _previous;

    _consume(TokenType.from, 'Expected a FROM here');

    final table = _tableReference();
    Expression where;
    if (table == null) {
      _error('Expected a table reference');
    }

    if (_matchOne(TokenType.where)) {
      where = expression();
    }

    return DeleteStatement(
      withClause: withClause,
      from: table,
      where: where,
    )..setSpan(withClause?.first ?? deleteToken, _previous);
  }

  UpdateStatement _update([WithClause withClause]) {
    if (!_matchOne(TokenType.update)) return null;
    final updateToken = _previous;

    FailureMode failureMode;
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

  InsertStatement _insertStmt([WithClause withClause]) {
    if (!_match(const [TokenType.insert, TokenType.replace])) return null;

    final firstToken = _previous;
    InsertMode insertMode;
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
      mode: insertMode,
      table: table,
      targetColumns: targetColumns,
      source: source,
      upsert: upsert,
    )..setSpan(withClause?.first ?? firstToken, _previous);
  }

  InsertSource _insertSource() {
    if (_matchOne(TokenType.$values)) {
      final values = <Tuple>[];
      do {
        // it will be a tuple, we don't turn on "orSubQuery"
        values.add(_consumeTuple() as Tuple);
      } while (_matchOne(TokenType.comma));
      return ValuesSource(values);
    } else if (_matchOne(TokenType.$default)) {
      _consume(TokenType.$values, 'Expected DEFAULT VALUES');
      return const DefaultValues();
    } else {
      return SelectInsertSource(
          _fullSelect() ?? _error('Expeced a select statement'));
    }
  }

  UpsertClause _upsertClauseOrNull() {
    if (!_matchOne(TokenType.on)) return null;

    final first = _previous;
    _consume(TokenType.conflict, 'Expected CONFLICT keyword for upsert clause');

    List<IndexedColumn> indexedColumns;
    Expression where;
    if (_matchOne(TokenType.leftParen)) {
      indexedColumns = _indexedColumns();

      _consume(TokenType.rightParen, 'Expected closing paren here');
      if (_matchOne(TokenType.where)) {
        where = expression();
      }
    }

    _consume(TokenType.$do,
        'Expected DO, followed by the action (NOTHING or UPDATE SET)');

    UpsertAction action;
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
    Expression where;
    if (_matchOne(TokenType.where)) {
      where = expression();
    }

    return DoUpdate(set, where: where)..setSpan(first, _previous);
  }

  @override
  WindowDefinition _windowDefinition() {
    _consume(TokenType.leftParen, 'Expected opening parenthesis');
    final leftParen = _previous;

    String baseWindowName;
    OrderByBase orderBy;

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
  FrameSpec _frameSpec() {
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
}
