part of '../analysis.dart';

/// Visitor that runs after all other steps ran and reports more complex lints
/// on an sql statement.
class LintingVisitor extends RecursiveVisitor<void, void> {
  final EngineOptions options;
  final AnalysisContext context;

  bool _isInTopLevelTriggerStatement = false;

  LintingVisitor(this.options, this.context);

  @override
  void visitBaseSelectStatement(BaseSelectStatement stmt, void arg) {
    if (_isInTopLevelTriggerStatement) {
      // If this select statement is used as a subqery, we're no longer in a
      // top-level trigger statements.
      final saved = _isInTopLevelTriggerStatement;
      _isInTopLevelTriggerStatement = stmt.parent is Block;
      super.visitBaseSelectStatement(stmt, arg);
      _isInTopLevelTriggerStatement = saved;
    } else {
      super.visitBaseSelectStatement(stmt, arg);
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression e, void arg) {
    final operator = e.operator.type;
    if ((operator == TokenType.dashRangle ||
            operator == TokenType.dashRangleRangle) &&
        options.version < SqliteVersion.v3_38) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.notSupportedInDesiredVersion,
        message: '`->` and `->>` require sqlite3 version 38',
        relevantNode: e.operator,
      ));
    }

    visitChildren(e, arg);
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e, void arg) {
    if (e.materializationHint != null &&
        options.version < SqliteVersion.v3_35) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.notSupportedInDesiredVersion,
        message: 'MATERIALIZED / NOT MATERIALIZED requires sqlite3 version 35',
        relevantNode: e.materialized ?? e,
      ));
    }

    visitChildren(e, arg);
  }

  @override
  void visitCreateTableStatement(CreateTableStatement e, void arg) {
    final schemaReader =
        SchemaFromCreateTable(driftExtensions: options.useDriftExtensions);
    var hasNonGeneratedColumn = false;
    var hasPrimaryKeyDeclaration = false;
    var isStrict = false;

    if (e.isStrict) {
      if (options.version < SqliteVersion.v3_37) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.notSupportedInDesiredVersion,
          message: 'STRICT tables are only supported from sqlite3 version 37',
          relevantNode: e.strict ?? e,
        ));
      } else {
        // only report warnings related to STRICT tables if strict tables are
        // supported.
        isStrict = true;
      }
    }

    // Ensure that a table declaration only has one PRIMARY KEY constraint
    void handlePrimaryKeyNode(AstNode node) {
      if (hasPrimaryKeyDeclaration) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.duplicatePrimaryKeyDeclaration,
          message: 'Duplicate PRIMARY KEY constraint found',
          relevantNode: node,
        ));
      }
      hasPrimaryKeyDeclaration = true;
    }

    for (final column in e.columns) {
      if (isStrict) {
        final typeName = column.typeName;

        if (typeName == null) {
          // Columns in strict tables must have a type name, even if it's
          // `ANY`.
          context.reportError(AnalysisError(
            type: AnalysisErrorType.noTypeNameInStrictTable,
            message: 'In `STRICT` tables, columns must have a type name!',
            relevantNode: column.nameToken ?? column,
          ));
        } else if (!schemaReader.isValidTypeNameForStrictTable(typeName)) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.invalidTypeNameInStrictTable,
            message: 'Invalid type name for a `STRICT` table.',
            relevantNode: column.typeNames?.toSingleEntity ?? column,
          ));
        }
      }

      var isGenerated = false;

      for (final constraint in column.constraints) {
        isGenerated = isGenerated || constraint is GeneratedAs;

        if (constraint is PrimaryKeyColumn) {
          handlePrimaryKeyNode(constraint);
        }
      }

      if (!isGenerated) {
        hasNonGeneratedColumn = true;
      }
    }

    for (final constraint in e.tableConstraints) {
      if (constraint is KeyClause && constraint.isPrimaryKey) {
        handlePrimaryKeyNode(constraint);
      }
    }

    if (e.withoutRowId && !hasPrimaryKeyDeclaration) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.missingPrimaryKey,
          message: 'Missing PRIMARY KEY declaration for a table without rowid.',
          relevantNode: e.tableNameToken ?? e,
        ),
      );
    }

    if (!hasNonGeneratedColumn) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.allColumnsAreGenerated,
          message: 'This table is missing a non-generated column',
          relevantNode: e.tableNameToken ?? e,
        ),
      );
    }

    visitChildren(e, arg);
  }

  @override
  void visitCreateTriggerStatement(CreateTriggerStatement e, void arg) {
    final topLevelBefore = _isInTopLevelTriggerStatement;
    _isInTopLevelTriggerStatement = true;

    if (e.onTable.resultSet?.unalias() case final on?) {
      if (on is View && !e.mode.isSupportedOnViews) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.invalidTriggerMode,
          relevantNode: e.onTable,
          message: 'Only `INSTEAD OF` triggers are allowed for views.',
        ));
      } else if (on is Table && !e.mode.isSupportedOnTables) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.invalidTriggerMode,
          relevantNode: e.onTable,
          message: '`INSTEAD OF` triggers are only allowed on views.',
        ));
      }
    }

    visitChildren(e, arg);
    _isInTopLevelTriggerStatement = topLevelBefore;
  }

  @override
  void visitCreateViewStatement(CreateViewStatement e, void arg) {
    final resolvedColumns = e.query.resolvedColumns;
    if (e.columns == null || resolvedColumns == null) {
      return super.visitCreateViewStatement(e, arg);
    }

    final amountOfNames = e.columns!.length;
    final amountOfColumns = resolvedColumns.length;

    if (amountOfNames != amountOfColumns) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.viewColumnNamesMismatch,
        relevantNode: e,
        message: 'This view declares $amountOfNames column names, but the '
            'inner select statement returns $amountOfColumns',
      ));
    }

    visitChildren(e, arg);
  }

  @override
  void visitDefaultValues(DefaultValues e, void arg) {
    // `DEFAULT VALUES` is not supported in a trigger, see https://www.sqlite.org/lang_insert.html
    if (_isInTopLevelTriggerStatement) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.synctactic,
          message: '`DEFAULT VALUES` cannot be used in a trigger.',
          relevantNode: e,
        ),
      );
    }

    visitChildren(e, arg);
  }

  @override
  void visitInExpression(InExpression e, void arg) {
    final expectedColumns = switch (e.left) {
      Tuple(:var expressions) => expressions.length,
      _ => 1,
    };

    switch (e.inside) {
      case Tuple tuple:
        for (final element in tuple.expressions) {
          final actualColumns = switch (element) {
            Tuple(:var expressions) => expressions.length,
            _ => 1,
          };

          if (expectedColumns != actualColumns) {
            context.reportError(AnalysisError(
              type: AnalysisErrorType.other,
              message: 'Expected $expectedColumns columns in this entry, got '
                  '$actualColumns',
              relevantNode: element,
            ));
          }
        }
      case SubQuery subquery:
        final columns = subquery.select.resolvedColumns;
        if (columns != null && columns.length != expectedColumns) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.other,
            message: 'The subquery must return $expectedColumns columns, '
                'it returns ${columns.length}',
            relevantNode: subquery,
          ));
        }
      case TableOrSubquery table:
        final columns =
            table.availableResultSet?.resultSet.resultSet?.resolvedColumns;
        if (columns != null && columns.length != expectedColumns) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.other,
            message: 'To be used in this `IN` expression, this table must '
                'have $expectedColumns columns (it has ${columns.length}).',
            relevantNode: table,
          ));
        }
    }

    visitChildren(e, arg);
  }

  @override
  void visitIsExpression(IsExpression e, void arg) {
    if (e.distinctFromSyntax && options.version < SqliteVersion.v3_39) {
      // `IS NOT DISTINCT FROM` is the same thing as `IS`
      final alternative = e.negated ? 'IS' : 'IS NOT';
      final source = (e.distinct != null && e.from != null)
          ? [e.distinct!, e.from!].toSingleEntity
          : e;

      context.reportError(AnalysisError(
        type: AnalysisErrorType.notSupportedInDesiredVersion,
        message:
            '`DISTINCT FROM` requires sqlite 3.39, try using `$alternative`',
        relevantNode: source,
      ));
    }

    visitChildren(e, arg);
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    for (final target in e.targetColumns) {
      final resolved = target.resolvedColumn;
      if (resolved is TableColumn && resolved.isGenerated) {
        context.reportError(
          AnalysisError(
            type: AnalysisErrorType.writeToGeneratedColumn,
            message: "This column is generated, and generated columns can't "
                'be inserted.',
            relevantNode: target,
          ),
        );
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitExpressionFunctionParameters(ExprFunctionParameters e, void arg) {
    if (e.distinct && e.parameters.length != 1) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.distinctAggregateWithWrongParameterCount,
        message: 'A `DISTINCT` aggregate must have exactly one argument',
        relevantNode: e.distinctKeyword ?? e,
      ));
    }

    visitChildren(e, arg);
  }

  @override
  void visitInvocation(SqlInvocation e, void arg) {
    final lowercaseCall = e.name.toLowerCase();
    if (options.addedFunctions.containsKey(lowercaseCall)) {
      options.addedFunctions[lowercaseCall]!.reportErrors(e, context);
    }

    final lowerCaseName = e.name.toLowerCase();
    if (lowerCaseName == 'printf' && options.version >= SqliteVersion.v3_38) {
      // `printf` was renamed to `format` in sqlite3 version 3.38
      if (options.version >= SqliteVersion.v3_38) {
        context.reportError(
          AnalysisError(
            type: AnalysisErrorType.hint,
            message: '`printf` was renamed to `format()`, consider using '
                'that function instead.',
            relevantNode: e,
          ),
        );
      }
    }

    // Warn when newer functions are used in an unsupported sqlite3 version.
    final minimumVersion = switch (lowerCaseName) {
      'format' || 'unixepoch' => SqliteVersion.v3_38,
      'unhex' => SqliteVersion.v3_41,
      'timediff' || 'octet_length' => SqliteVersion.v3_43,
      'concat' || 'concat_ws' || 'string_agg' => SqliteVersion.v3_44,
      _ => null,
    };

    if (minimumVersion != null && options.version < minimumVersion) {
      final versionStr = '${minimumVersion.major}.${minimumVersion.minor}';

      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.notSupportedInDesiredVersion,
          message: '`${e.name}` requires sqlite $versionStr or later',
          relevantNode: e.nameToken ?? e,
        ),
      );
    }

    visitChildren(e, arg);
  }

  @override
  void visitJoinOperator(JoinOperator e, void arg) {
    if ((e.operator == JoinOperatorKind.right ||
            e.operator == JoinOperatorKind.full) &&
        options.version < SqliteVersion.v3_39) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.notSupportedInDesiredVersion,
          message: '`RIGHT` and `FULL` joins require sqlite 3.39.',
          relevantNode: e,
        ),
      );
    }
  }

  @override
  void visitRaiseExpression(RaiseExpression e, void arg) {
    if (!_isInTopLevelTriggerStatement) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.raiseMisuse,
        relevantNode: e,
        message: 'RAISE can only be used in a trigger.',
      ));
    }
  }

  @override
  void visitReturning(Returning e, void arg) {
    // RETURNING was added in sqlite version 3.35.0
    if (context.engineOptions.version < SqliteVersion.v3_35) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.notSupportedInDesiredVersion,
        message: 'RETURNING requires sqlite version 3.35 or later',
        relevantNode: e,
      ));

      return;
    }

    // https://www.sqlite.org/lang_returning.html#limitations_and_caveats
    // Returning is not allowed in triggers
    if (_isInTopLevelTriggerStatement) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.illegalUseOfReturning,
        message: 'RETURNING is not allowed in triggers',
        relevantNode: e,
      ));
    }

    // Returning is not allowed against virtual tables
    final parent = e.parent;
    if (parent is HasPrimarySource) {
      final source = parent.table;
      if (source is TableReference) {
        final referenced = source.resultSet?.unalias();
        if (referenced is Table && referenced.isVirtual) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.illegalUseOfReturning,
            message: 'RETURNING is not allowed against virtual tables',
            relevantNode: e,
          ));
        }
      }
    }

    for (final column in e.columns) {
      // Table wildcards are not currently allowed, see
      // https://www.sqlite.org/src/info/132994c8b1063bfb
      if (column is StarResultColumn && column.tableName != null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.synctactic,
          message: 'Columns in RETURNING may not use the TABLE.* syntax',
          relevantNode: column,
        ));
      } else if (column is ExpressionResultColumn) {
        // While we're at it, window expressions aren't allowed either
        if (column.expression is WindowFunctionInvocation) {
          context.reportError(
            AnalysisError(
              type: AnalysisErrorType.illegalUseOfReturning,
              message: 'Aggregate expressions are not allowed in RETURNING',
              relevantNode: column.expression,
            ),
          );
        }
      }
    }

    visitChildren(e, arg);
  }

  void _checkForGeneratedColumn(Reference column) {
    final target = column.resolvedColumn;

    if (target is TableColumn && target.isGenerated) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.writeToGeneratedColumn,
          message: 'This column is generated, and generated columns cannot be '
              'updated explicitly.',
          relevantNode: column,
        ),
      );
    }
  }

  @override
  void visitSingleColumnSetComponent(SingleColumnSetComponent e, void arg) {
    _checkForGeneratedColumn(e.column);
    visitChildren(e, arg);
  }

  @override
  void visitMultiColumnSetComponent(MultiColumnSetComponent e, void arg) {
    for (final column in e.columns) {
      _checkForGeneratedColumn(column);
    }

    if (e.rowValue is Tuple &&
        e.columns.length != (e.rowValue as Tuple).expressions.length) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.cteColumnCountMismatch,
          message:
              'Length of column-name-list must match length of row values.',
          relevantNode: e.rowValue,
        ),
      );
    } else if (e.rowValue is SubQuery &&
        e.columns.length !=
            (e.rowValue as SubQuery).select.resolvedColumns?.length) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.cteColumnCountMismatch,
          message:
              'Length of column-name-list must match length of columns returned by SubQuery.',
          relevantNode: e.rowValue,
        ),
      );
    }

    visitChildren(e, arg);
  }

  @override
  void visitTableConstraint(TableConstraint e, void arg) {
    if (e is KeyClause && e.isPrimaryKey) {
      // Primary key clauses may only include simple columns
      for (final column in e.columns) {
        final expr = column.expression;
        if (expr is! Reference || expr.entityName != null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.synctactic,
            message: 'Only column names can be used in a PRIMARY KEY clause',
            relevantNode: expr,
          ));
        }
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitTableReference(TableReference e, void arg) {
    final parent = e.parent;
    if (parent is HasPrimarySource && parent.table == e) {
      // The source of a `INSERT`, `UPDATE` or `DELETE` statement must not have
      // an alias in `CREATE TRIGGER` statements.
      if (_isInTopLevelTriggerStatement && e.as != null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.synctactic,
          message:
              'The source must not have an `AS` alias when used in a trigger.',
          relevantNode: e,
        ));
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitTuple(Tuple e, void arg) {
    if (!e.usedAsRowValue) return;

    bool isRowValue(Expression? expr) => expr is Tuple || expr is SubQuery;

    var parent = e.parent;
    var isAllowed = false;

    if (parent is WhenComponent && e == parent.when) {
      // look at the surrounding case expression
      parent = parent.parent;
    }

    if (parent is BinaryExpression) {
      // Source: https://www.sqlite.org/rowvalue.html#syntax
      const allowedTokens = [
        TokenType.less,
        TokenType.lessEqual,
        TokenType.more,
        TokenType.moreEqual,
        TokenType.equal,
        TokenType.doubleEqual,
        TokenType.lessMore,
        TokenType.$is,
      ];

      if (allowedTokens.contains(parent.operator.type)) {
        isAllowed = true;
      }
    } else if (parent is BetweenExpression) {
      // Allowed if all value are row values or subqueries
      isAllowed = !parent.childNodes.any((e) => !isRowValue(e));
    } else if (parent is CaseExpression) {
      // Allowed if we have something to compare against and all comparisons
      // are row values
      if (parent.base == null) {
        isAllowed = false;
      } else {
        final comparisons = <Expression?>[
          parent.base,
          for (final branch in parent.whens) branch.when
        ];

        isAllowed = !comparisons.any((e) => !isRowValue(e));
      }
    } else if (parent is InExpression) {
      // For in expressions we have a more accurate analysis on whether tuples
      // are allowed that looks at both the LHS and the RHS.
      isAllowed = true;
    } else if (parent is SetComponent) {
      isAllowed = true;
    }

    if (!isAllowed) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.rowValueMisuse,
        relevantNode: e,
        message: 'Row values can only be used as expressions in comparisons',
      ));
    }
  }

  @override
  void visitUpsertClause(UpsertClause e, void arg) {
    final hasMultipleClauses = e.entries.length > 1;

    if (hasMultipleClauses && options.version < SqliteVersion.v3_35) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.notSupportedInDesiredVersion,
        relevantNode: e,
        message:
            'Multiple on conflict clauses require sqlite version 3.35 or later',
      ));
    }

    visitChildren(e, arg);
  }

  @override
  void visitValuesSelectStatement(ValuesSelectStatement e, void arg) {
    final expectedColumns = e.resolvedColumns!.length;

    for (final tuple in e.values) {
      final elementsInTuple = tuple.expressions.length;

      if (elementsInTuple != expectedColumns) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.valuesSelectCountMismatch,
          relevantNode: tuple,
          message: 'The surrounding VALUES clause has $expectedColumns '
              'columns, but this tuple only has $elementsInTuple',
        ));
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitWithClause(WithClause e, void arg) {
    if (_isInTopLevelTriggerStatement) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.synctactic,
        relevantNode: e.withToken ?? e,
        message: 'WITH clauses cannot appear in triggers.',
      ));
    }

    visitChildren(e, arg);
  }
}
