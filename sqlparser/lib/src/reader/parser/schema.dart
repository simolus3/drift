part of 'parser.dart';

const _tokensInTypename = [
  TokenType.identifier,
  TokenType.leftParen,
  TokenType.rightParen,
  TokenType.numberLiteral,
];

mixin SchemaParser on ParserBase {
  CreateTableStatement _createTable() {
    if (!_matchOne(TokenType.create)) return null;
    final first = _previous;

    _consume(TokenType.table, 'Expected TABLE keyword here');

    var ifNotExists = false;

    if (_matchOne(TokenType.$if)) {
      _consume(TokenType.not, 'Expected IF to be followed by NOT EXISTS');
      _consume(TokenType.exists, 'Expected IF NOT to be followed by EXISTS');
      ifNotExists = true;
    }

    final tableIdentifier = _consumeIdentifier('Expected a table name');

    // we don't currently support CREATE TABLE x AS SELECT ... statements
    _consume(
        TokenType.leftParen, 'Expected opening parenthesis to list columns');

    final columns = <ColumnDefinition>[];
    final tableConstraints = <TableConstraint>[];
    // the columns must come before the table constraints!
    var encounteredTableConstraint = false;

    do {
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
    } while (_matchOne(TokenType.comma));

    _consume(TokenType.rightParen, 'Expected closing parenthesis');

    var withoutRowId = false;
    if (_matchOne(TokenType.without)) {
      _consume(
          TokenType.rowid, 'Expected ROWID to complete the WITHOUT ROWID part');
      withoutRowId = true;
    }

    return CreateTableStatement(
      ifNotExists: ifNotExists,
      tableName: tableIdentifier.identifier,
      withoutRowId: withoutRowId,
      columns: columns,
      tableConstraints: tableConstraints,
    )..setSpan(first, _previous);
  }

  ColumnDefinition _columnDefinition() {
    final name = _consume(TokenType.identifier, 'Expected a column name')
        as IdentifierToken;

    final typeNameBuilder = StringBuffer();
    while (_match(_tokensInTypename)) {
      typeNameBuilder.write(_previous.lexeme);
    }

    final typeName =
        typeNameBuilder.isEmpty ? null : typeNameBuilder.toString();

    final constraints = <ColumnConstraint>[];
    ColumnConstraint constraint;
    while ((constraint = _columnConstraint(orNull: true)) != null) {
      constraints.add(constraint);
    }

    return ColumnDefinition(
      columnName: name.identifier,
      typeName: typeName,
      constraints: constraints,
    )..setSpan(name, _previous);
  }

  ColumnConstraint _columnConstraint({bool orNull = false}) {
    final first = _peek;

    final resolvedName = _constraintNameOrNull();

    if (_matchOne(TokenType.primary)) {
      _consume(TokenType.key, 'Expected KEY to complete PRIMARY KEY clause');

      final mode = _orderingModeOrNull();
      final conflict = _conflictClauseOrNull();
      final hasAutoInc = _matchOne(TokenType.autoincrement);

      return PrimaryKeyColumn(resolvedName,
          autoIncrement: hasAutoInc, mode: mode, onConflict: conflict)
        ..setSpan(first, _previous);
    }
    if (_matchOne(TokenType.not)) {
      _consume(TokenType.$null, 'Expected NULL to complete NOT NULL');

      return NotNull(resolvedName, onConflict: _conflictClauseOrNull())
        ..setSpan(first, _previous);
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
      Expression expr = _literalOrNull();

      // when not a literal, expect an expression in parentheses
      expr ??= _expressionInParentheses();

      return Default(resolvedName, expr);
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

    // no known column constraint matched. If orNull is set and we're not
    // guaranteed to be in a constraint clause (started with CONSTRAINT), we
    // can return null
    if (orNull && resolvedName == null) {
      return null;
    }
    _error('Expected a constraint (primary key, nullability, etc.)');
  }

  TableConstraint _tableConstraintOrNull() {
    final first = _peek;
    final name = _constraintNameOrNull();

    if (_match([TokenType.unique, TokenType.primary])) {
      final isPrimaryKey = _previous.type == TokenType.primary;

      if (isPrimaryKey) {
        _consume(TokenType.key, 'Expected KEY to start PRIMARY KEY clause');
      }

      final columns = _listColumnsInParentheses(allowEmpty: false);
      final conflictClause = _conflictClauseOrNull();

      return KeyClause(name,
          isPrimaryKey: isPrimaryKey,
          indexedColumns: columns,
          onConflict: conflictClause)
        ..setSpan(first, _previous);
    } else if (_matchOne(TokenType.check)) {
      final expr = _expressionInParentheses();
      return CheckTable(name, expr)..setSpan(first, _previous);
    } else if (_matchOne(TokenType.foreign)) {
      _consume(TokenType.key, 'Expected KEY to start FOREIGN KEY clause');
      final columns = _listColumnsInParentheses(allowEmpty: false);
      final clause = _foreignKeyClause();

      return ForeignKeyTableConstraint(name, columns: columns, clause: clause)
        ..setSpan(first, _previous);
    }

    if (name != null) {
      // if a constraint was started with CONSTRAINT <name> but then we didn't
      // find a constraint, that's an syntax error
      _error('Expected a table constraint (e.g. a primary key)');
    }
    return null;
  }

  String _constraintNameOrNull() {
    if (_matchOne(TokenType.constraint)) {
      final name = _consumeIdentifier('Expect a name for the constraint here');
      return name.identifier;
    }
    return null;
  }

  Expression _expressionInParentheses() {
    _consume(TokenType.leftParen, 'Expected opening parenthesis');
    final expr = expression();
    _consume(TokenType.rightParen, 'Expected closing parenthesis');
    return expr;
  }

  ConflictClause _conflictClauseOrNull() {
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

    ReferenceAction onDelete, onUpdate;

    while (_matchOne(TokenType.on)) {
      if (_matchOne(TokenType.delete)) {
        onDelete = _referenceAction();
      } else if (_matchOne(TokenType.update)) {
        onUpdate = _referenceAction();
      } else {
        _error('Expected either DELETE or UPDATE');
      }
    }

    return ForeignKeyClause(
      foreignTable: foreignTableName,
      columnNames: columnNames,
      onUpdate: onUpdate,
      onDelete: onDelete,
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
