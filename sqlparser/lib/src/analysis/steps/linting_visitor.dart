part of '../analysis.dart';

/// Visitor that runs after all other steps ran and reports more complex lints
/// on an sql statement.
class LintingVisitor extends RecursiveVisitor<void, void> {
  final EngineOptions options;
  final AnalysisContext context;

  bool _isTopLevelStatement = true;

  LintingVisitor(this.options, this.context);

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
        SchemaFromCreateTable(moorExtensions: options.useMoorExtensions);
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

          // A primary key in a STRICT table must be annoted with "NOT NULL"
          if (isStrict && !column.isNonNullable) {
            context.reportError(AnalysisError(
              type: AnalysisErrorType.nullableColumnInStrictPrimaryKey,
              message:
                  'The column is used as a `PRIMARY KEY` in a `STRICT` table, '
                  'which means that is must be marked as `NOT NULL`',
              relevantNode: constraint,
            ));
          }
        }
      }

      if (!isGenerated) {
        hasNonGeneratedColumn = true;
      }
    }

    for (final constraint in e.tableConstraints) {
      if (constraint is KeyClause && constraint.isPrimaryKey) {
        handlePrimaryKeyNode(constraint);

        if (isStrict) {
          for (final columnName in constraint.columns) {
            final expr = columnName.expression;
            if (expr is! Reference) continue;

            final column = e.columns.firstWhereOrNull((c) =>
                c.columnName.toLowerCase() == expr.columnName.toLowerCase());
            if (column != null && !column.isNonNullable) {
              context.reportError(
                AnalysisError(
                  type: AnalysisErrorType.nullableColumnInStrictPrimaryKey,
                  message:
                      'This column must be marked as `NOT NULL` to be used in '
                      'a `PRIMARY KEY` clause of a `STRICT` table.',
                  relevantNode: columnName,
                ),
              );
            }
          }
        }
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
    final topLevelBefore = _isTopLevelStatement;
    _isTopLevelStatement = false;
    visitChildren(e, arg);
    _isTopLevelStatement = topLevelBefore;
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
  void visitInvocation(SqlInvocation e, void arg) {
    final lowercaseCall = e.name.toLowerCase();
    if (options.addedFunctions.containsKey(lowercaseCall)) {
      options.addedFunctions[lowercaseCall]!.reportErrors(e, context);
    }

    visitChildren(e, arg);
  }

  @override
  void visitRaiseExpression(RaiseExpression e, void arg) {
    if (_isTopLevelStatement) {
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
    if (!_isTopLevelStatement) {
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
        if (column.expression is AggregateExpression) {
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

  @override
  void visitSetComponent(SetComponent e, void arg) {
    final target = e.column.resolvedColumn;

    if (target is TableColumn && target.isGenerated) {
      context.reportError(
        AnalysisError(
          type: AnalysisErrorType.writeToGeneratedColumn,
          message: 'This column is generated, and generated columns cannot be '
              'updated explicitly.',
          relevantNode: e.column,
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
      // In expressions are tricky. The rhs can always be a row value, but the
      // lhs can only be a row value if the rhs is a subquery
      isAllowed = e == parent.inside || parent.inside is SubQuery;
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
}
