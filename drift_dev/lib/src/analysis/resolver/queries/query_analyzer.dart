import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:drift/drift.dart' as drift;
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:sqlparser/sqlparser.dart' as sql;
import 'package:sqlparser/utils/find_referenced_tables.dart';

import '../../backend.dart';
import '../../driver/driver.dart';
import '../../driver/state.dart';
import '../dart/helper.dart';
import '../drift/sqlparser/drift_lints.dart';
import '../drift/sqlparser/mapping.dart';
import '../../results/results.dart';
import '../shared/dart_types.dart';
import 'existing_row_class.dart';
import 'nested_queries.dart';
import 'required_variables.dart';

/// The context contains all data that is required to create an [SqlQuery]. This
/// class is simply there to bundle the data.
class _QueryHandlerContext {
  final List<FoundElement> foundElements;
  final List<SyntacticElementReference> elementReferences;
  final AstNode root;
  final NestedQueriesContainer? nestedScope;
  final String queryName;
  final String? requestedResultClass;
  final RequestedQueryResultType? requestedResultType;

  final DriftTableName? sourceForFixedName;

  _QueryHandlerContext({
    required List<FoundElement> foundElements,
    required List<SyntacticElementReference> elementReferences,
    required this.root,
    required this.queryName,
    required this.nestedScope,
    this.requestedResultClass,
    this.requestedResultType,
    this.sourceForFixedName,
  })  : foundElements = List.unmodifiable(foundElements),
        elementReferences = List.unmodifiable(elementReferences);
}

/// Maps an [AnalysisContext] from the sqlparser to a [SqlQuery] from this
/// generator package by determining its type, return columns, variables and so
/// on.
class QueryAnalyzer {
  final AnalysisContext context;
  final FileState fromFile;
  final DriftAnalysisDriver driver;
  final KnownDriftTypes knownTypes;
  final RequiredVariables requiredVariables;
  final Map<String, DriftElement> referencesByName;

  final Map<String, dart.Expression> _resolvedExpressions = {};

  /// Found tables and views found need to be shared between the query and
  /// all subqueries to not muss any updates when watching query.
  late Set<Table> _foundTables;
  late Set<View> _foundViews;

  /// Used to create a unique name for every nested query. This needs to be
  /// shared between queries, therefore this should not be part of the
  /// context.
  int nestedQueryCounter = 0;

  final List<AnalysisError> lints = [];

  QueryAnalyzer(
    this.context,
    this.fromFile,
    this.driver, {
    required this.knownTypes,
    required List<DriftElement> references,
    this.requiredVariables = RequiredVariables.empty,
  }) : referencesByName = {
          for (final reference in references)
            reference.id.name.toLowerCase(): reference,
        };

  E _lookupReference<E extends DriftElement?>(String name) {
    return referencesByName[name.toLowerCase()] as E;
  }

  /// Analyzes the query from its [declaration].
  ///
  /// This runs drfit-specific query analysis and lints on the query. It will
  /// also detect read or written tables and a suitable result set for this
  /// query in Dart.
  ///
  /// The [sourceForCustomName] can be set to the syntactic source responsible
  /// for a [DefinedSqlQuery.existingDartType] or[DefinedSqlQuery.resultClassName],
  /// respectively. It will improve the highlighted source span in error
  /// messages.
  Future<SqlQuery> analyze(DriftQueryDeclaration declaration,
      {DriftTableName? sourceForCustomName}) async {
    await _resolveDartTokens(declaration);

    final nestedAnalyzer = NestedQueryAnalyzer();
    NestedQueriesContainer? nestedScope;

    if (context.root is SelectStatement) {
      nestedScope = nestedAnalyzer.analyzeRoot(context.root as SelectStatement);
    }

    final (foundElements, references) = _extractElements(
      ctx: context,
      root: context.root,
      required: requiredVariables,
      nestedScope: nestedScope,
    );
    _verifyNoSkippedIndexes(foundElements);

    String? requestedResultClass;
    RequestedQueryResultType? requestedResultType;
    if (declaration is DefinedSqlQuery) {
      requestedResultClass = declaration.resultClassName;
      requestedResultType = declaration.existingDartType;
    }

    final query = _mapToDrift(_QueryHandlerContext(
      foundElements: foundElements,
      elementReferences: references,
      queryName: declaration.name,
      requestedResultClass: requestedResultClass,
      requestedResultType: requestedResultType,
      root: context.root,
      nestedScope: nestedScope,
      sourceForFixedName: sourceForCustomName,
    ));

    final linter = DriftSqlLinter(
      context,
      references: referencesByName.values,
      contextRootIsQuery: true,
    );
    linter.collectLints();
    lints
      ..addAll(context.errors)
      ..addAll(linter.sqlParserErrors)
      ..addAll(nestedAnalyzer.errors);

    return query;
  }

  Future<void> _resolveDartTokens(DriftQueryDeclaration declaration) async {
    if (declaration is DefinedSqlQuery) {
      for (final expression in declaration.dartTokens) {
        try {
          final resolved = await driver.backend.resolveExpression(
            fromFile.ownUri,
            expression,
            fromFile.discovery?.importDependencies
                    .map((e) => e.toString())
                    .where((e) => e.endsWith('.dart')) ??
                const Iterable.empty(),
          );

          _resolvedExpressions[expression] = resolved;
        } on CannotReadExpressionException catch (e) {
          lints.add(AnalysisError(
            type: AnalysisErrorType.other,
            message: 'Could not read expression: ${e.msg}',
          ));
        }
      }
    }
  }

  SqlQuery _mapToDrift(_QueryHandlerContext queryContext) {
    if (queryContext.root is BaseSelectStatement) {
      return _handleSelect(queryContext);
    } else if (queryContext.root is UpdateStatement ||
        queryContext.root is DeleteStatement ||
        queryContext.root is InsertStatement) {
      return _handleUpdate(queryContext);
    } else {
      throw StateError(
          'Unexpected sql: Got ${queryContext.root}, expected insert, select, '
          'update or delete');
    }
  }

  void _applyFoundTables(ReferencedTablesVisitor visitor) {
    _foundTables = visitor.foundTables;
    _foundViews = visitor.foundViews;
  }

  UpdatingQuery _handleUpdate(_QueryHandlerContext queryContext) {
    final root = queryContext.root;

    final updatedFinder = UpdatedTablesVisitor();
    root.acceptWithoutArg(updatedFinder);
    _applyFoundTables(updatedFinder);

    final isInsert = root is InsertStatement;

    InferredResultSet? resultSet;
    if (root is StatementReturningColumns) {
      final columns = root.returnedResultSet?.resolvedColumns;

      if (columns != null) {
        final syntacticSource = root.returning?.columns;
        resultSet = _inferResultSet(queryContext, columns, syntacticSource);
      }
    }

    return UpdatingQuery(
      queryContext.queryName,
      context,
      root,
      queryContext.foundElements,
      queryContext.elementReferences,
      updatedFinder.writtenTables
          .map((write) {
            final table = _lookupReference<DriftTable?>(write.table.name);
            drift.UpdateKind kind;

            switch (write.kind) {
              case UpdateKind.insert:
                kind = drift.UpdateKind.insert;
                break;
              case UpdateKind.update:
                kind = drift.UpdateKind.update;
                break;
              case UpdateKind.delete:
                kind = drift.UpdateKind.delete;
                break;
            }

            return table != null ? WrittenDriftTable(table, kind) : null;
          })
          .whereType<WrittenDriftTable>()
          .toList(),
      isInsert: isInsert,
      resultSet: resultSet,
    );
  }

  SqlSelectQuery _handleSelect(_QueryHandlerContext queryContext) {
    final tableFinder = ReferencedTablesVisitor();
    final root = queryContext.root;
    queryContext.root.acceptWithoutArg(tableFinder);

    _applyFoundTables(tableFinder);

    final driftTables = _foundTables
        .map((tbl) => _lookupReference<DriftTable?>(tbl.name))
        .whereType<DriftTable>()
        .toList();
    final driftViews = _foundViews
        .map((tbl) => _lookupReference<DriftView?>(tbl.name))
        .whereType<DriftView>()
        .toList();

    final driftEntities = [...driftTables, ...driftViews];

    final resolvedColumns = (root as BaseSelectStatement).resolvedColumns!;
    List<sql.ResultColumn>? syntacticColumns;

    if (root is SelectStatement) {
      syntacticColumns = root.columns;
    }

    return SqlSelectQuery(
      queryContext.queryName,
      context,
      queryContext.root,
      queryContext.foundElements,
      queryContext.elementReferences,
      driftEntities,
      _inferResultSet(queryContext, resolvedColumns, syntacticColumns),
      queryContext.requestedResultClass,
      queryContext.nestedScope,
    );
  }

  InferredResultSet _inferResultSet(
    _QueryHandlerContext queryContext,
    List<Column> rawColumns,
    List<sql.ResultColumn>? syntacticColumns,
  ) {
    final candidatesForSingleTable = {..._foundTables, ..._foundViews};
    final columns = <ResultColumn>[];

    void handleScalarColumn(Column column,
        [sql.ExpressionResultColumn? source]) {
      final type = context.typeOf(column).type;
      final driftType = driver.typeMapping.sqlTypeToDrift(type);
      final mappedBy = source?.mappedBy;
      AppliedTypeConverter? converter;

      if (type?.hint<TypeConverterHint>() case final TypeConverterHint h) {
        converter = h.converter;
      } else if (mappedBy != null) {
        final dartExpression = _resolvedExpressions[mappedBy.mapper.dartCode];
        if (dartExpression != null) {
          converter = readTypeConverter(
            knownTypes.helperLibrary,
            dartExpression,
            driftType,
            type?.nullable ?? true,
            (msg) => lints.add(
              AnalysisError(
                type: AnalysisErrorType.other,
                message: msg,
                relevantNode: mappedBy,
              ),
            ),
            knownTypes,
          )?..owningColumn = null;
        }
      }

      columns.add(ScalarResultColumn(
          column.name, driftType, type?.nullable ?? true,
          typeConverter: converter, sqlParserColumn: column));

      final resultSet = _resultSetOfColumn(column);
      candidatesForSingleTable.removeWhere((t) => t != resultSet);
    }

    // We prefer to extract the result set from syntactic columns, as this gives
    // us the opportunity to get the ordering between "scalar" result columns
    // and nested result sets right. We might not have a syntactic source
    // though (for instance if a top-level `VALUES` select is used), so we
    // fall-back to the resolved schema columns if necessary.
    if (syntacticColumns == null) {
      rawColumns.forEach(handleScalarColumn);
    } else {
      for (final column in syntacticColumns) {
        final resolvedColumns = column.resolvedColumns;

        if (column is NestedStarResultColumn) {
          final resolved = _resolveNestedResultTable(queryContext, column);

          if (resolved != null) {
            // The single table optimization doesn't make sense when nested result
            // sets are present.
            candidatesForSingleTable.clear();
            columns.add(resolved);
          }
        } else if (column is NestedQueryColumn) {
          candidatesForSingleTable.clear();
          columns.add(_resolveNestedResultQuery(queryContext, column));
        } else {
          if (resolvedColumns == null) continue;

          final definition =
              column is sql.ExpressionResultColumn ? column : null;

          // "Regular" column that either is or expands to a list of scalar
          // result columns.
          for (final column in resolvedColumns) {
            handleScalarColumn(column, definition);
          }
        }
      }
    }

    // if all columns read from the same table, and all columns in that table
    // are present in the result set, we can use the data class we generate for
    // that table instead of generating another class just for this result set.
    InferredResultSet? resultSet;

    if (candidatesForSingleTable.length == 1) {
      final table = candidatesForSingleTable.single;
      final driftTable =
          _lookupReference<DriftElementWithResultSet?>(table.name);

      if (driftTable == null) {
        // References a table not declared in any drift api (dart or drift file).
        // This can happen for internal sqlite tables
        return InferredResultSet(null, columns);
      }

      final resultEntryToColumn = <ResultColumn, String>{};
      final resultColumnNameToDrift = <String, DriftColumn>{};
      var matches = true;

      // go trough all columns of the table in question
      for (final column in driftTable.columns) {
        // check if this column from the table is present in the result set
        final tableColumn = table.findColumn(column.nameInSql);
        final inResultSet =
            rawColumns.where((t) => _toTableOrViewColumn(t) == tableColumn);

        if (inResultSet.length == 1) {
          // it is! Remember the correct getter name from the data class for
          // later when we write the mapping code.
          final columnIndex = rawColumns.indexOf(inResultSet.single);
          final resultColumn = columns[columnIndex] as ScalarResultColumn;

          resultEntryToColumn[resultColumn] = column.nameInDart;
          resultColumnNameToDrift[resultColumn.name] = column;
        } else {
          // it's not, so no match
          matches = false;
          break;
        }
      }

      // we have established that all columns in resultEntryToColumn do appear
      // in the drift table. Now check for set equality.
      if (rawColumns.length != driftTable.columns.length) {
        matches = false;
      }

      if (matches) {
        final match = MatchingDriftTable(driftTable, resultColumnNameToDrift);
        resultSet = InferredResultSet(match, columns)
          ..forceDartNames(resultEntryToColumn);
      }
    }

    resultSet ??= InferredResultSet(
      null,
      columns,
      resultClassName: queryContext.requestedResultClass,
    );

    if (queryContext.requestedResultType != null) {
      final matcher = MatchExistingTypeForQuery(knownTypes, (message) {
        lints.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: message,
          relevantNode: queryContext.sourceForFixedName ?? queryContext.root,
        ));
      });

      resultSet = matcher.applyTo(resultSet, queryContext.requestedResultType!);
    }

    return resultSet;
  }

  /// Resolves a "nested star" column.
  ///
  /// Nested star columns refer to an existing result set, but instructs drift
  /// that this result set should be handled as a nested type in Dart. For an
  /// example, see https://drift.simonbinder.eu/docs/using-sql/drift_files/#nested-results
  NestedResultTable? _resolveNestedResultTable(
      _QueryHandlerContext queryContext, NestedStarResultColumn column) {
    final originalResult = column.resultSet;
    final result = originalResult?.unalias();
    final rawColumns = result?.resolvedColumns;

    if (result == null || rawColumns == null) return null;

    final driftResultSet = _inferResultSet(
      _QueryHandlerContext(
        foundElements: queryContext.foundElements,
        elementReferences: queryContext.elementReferences,
        root: queryContext.root,
        queryName: queryContext.queryName,
        nestedScope: queryContext.nestedScope,
        sourceForFixedName: queryContext.sourceForFixedName,
        // Remove desired result class, if any. It will be resolved by the
        // parent _inferResultSet call.
      ),
      rawColumns,
      null,
    );

    final analysis = JoinModel.of(column);
    final isNullable =
        analysis == null || analysis.isNullableTable(originalResult!);

    final queryIndex = nestedQueryCounter++;
    final resultClassName =
        '${ReCase(queryContext.queryName).pascalCase}NestedColumn$queryIndex';

    return NestedResultTable(
      from: column,
      name: column.as ?? column.tableName,
      innerResultSet: driftResultSet,
      nameForGeneratedRowClass: resultClassName,
      isNullable: isNullable,
    );
  }

  /// Resolves a `LIST` result column.
  ///
  /// The `LIST` macro allows defining a subquery whose results should be
  /// exposed as a Dart list.
  /// For an example, see https://drift.simonbinder.eu/docs/using-sql/drift_files/#list-subqueries
  NestedResultQuery _resolveNestedResultQuery(
      _QueryHandlerContext queryContext, NestedQueryColumn column) {
    final childScope = queryContext.nestedScope?.nestedQueries[column];

    final (foundElements, references) = _extractElements(
      ctx: context,
      root: column.select,
      required: requiredVariables,
      nestedScope: childScope,
    );
    _verifyNoSkippedIndexes(foundElements);

    final queryIndex = nestedQueryCounter++;

    final name = 'nested_query_$queryIndex';
    column.queryName = name;

    var resultClassName = ReCase(queryContext.queryName).pascalCase;
    if (column.as != null) {
      resultClassName += ReCase(column.as!).pascalCase;
    } else {
      resultClassName += 'NestedQuery$queryIndex';
    }

    return NestedResultQuery(
      from: column,
      query: _handleSelect(_QueryHandlerContext(
        queryName: name,
        requestedResultClass: resultClassName,
        root: column.select,
        foundElements: foundElements,
        elementReferences: references,
        nestedScope: childScope,
      )),
    );
  }

  Column? _toTableOrViewColumn(Column? c) {
    // ignore: literal_only_boolean_expressions
    while (true) {
      if (c is TableColumn || c is ViewColumn) {
        return c;
      } else if (c is ExpressionColumn) {
        final expression = c.expression;
        if (expression is Reference) {
          final resolved = expression.resolved;
          if (resolved is Column) {
            c = resolved;
            continue;
          }
        }
        // Not a reference to a column
        return null;
      } else if (c is DelegatedColumn) {
        c = c.innerColumn;
      } else {
        return null;
      }
    }
  }

  ResultSet? _resultSetOfColumn(Column c) {
    final mapped = _toTableOrViewColumn(c);
    if (mapped == null) return null;

    if (mapped is ViewColumn) {
      return mapped.view;
    } else {
      return (mapped as TableColumn).table;
    }
  }

  /// Extracts variables and Dart templates from the AST tree starting at
  /// [root], but nested queries are excluded. Variables are sorted by their
  /// ascending index. Placeholders are sorted by the position they have in the
  /// query. When comparing variables and placeholders, the variable comes first
  /// if the first variable with the same index appears before the placeholder.
  ///
  /// Additionally, the following assumptions can be made if this method returns
  /// without throwing:
  ///  - array variables don't have an explicit index
  ///  - if an explicitly indexed variable appears AFTER an array variable or
  ///    a Dart placeholder, its indexed is LOWER than that element. This means
  ///    that elements can be expanded into multiple variables without breaking
  ///    variables that appear after them.
  (List<FoundElement>, List<SyntacticElementReference>) _extractElements({
    required AnalysisContext ctx,
    required AstNode root,
    NestedQueriesContainer? nestedScope,
    RequiredVariables required = RequiredVariables.empty,
  }) {
    final collector = _FindElements()..visit(root, nestedScope);

    // this contains variable references. For instance, SELECT :a = :a would
    // contain two entries, both referring to the same variable. To do that,
    // we use the fact that each variable has a unique index.
    final variables = collector.variables;
    final placeholders = collector.dartPlaceholders;

    final merged = _mergeVarsAndPlaceholders(variables, placeholders);

    final foundElements = <FoundElement>[];
    final references = <SyntacticElementReference>[];

    // we don't allow variables with an explicit index after an array. For
    // instance: SELECT * FROM t WHERE id IN ? OR id = ?2. The reason this is
    // not allowed is that we expand the first arg into multiple vars at runtime
    // which would break the index. The initial high values can be arbitrary.
    // We've chosen 999 because most sqlite binaries don't allow more variables.
    var maxIndex = 999;
    var currentIndex = 0;

    void addNewElement(FoundElement element) {
      foundElements.add(element);
      references.add(SyntacticElementReference(element));
    }

    for (final used in merged) {
      if (used is Variable) {
        if (used.resolvedIndex == currentIndex) {
          references.add(SyntacticElementReference(foundElements.last));
          continue; // already handled, we only report a single variable / index
        }

        currentIndex = used.resolvedIndex!;
        final name = (used is ColonNamedVariable) ? used.name : null;
        final explicitIndex =
            (used is NumberedVariable) ? used.explicitIndex : null;
        final forCapture = used.meta<CapturedVariable>();

        ResolveResult internalType;
        if (forCapture != null) {
          // If this variable was introduced to replace a reference from a
          // `LIST` query to an outer query, use the type of the reference
          // instead of the synthetic variable that we're replacing it with.
          internalType = ctx.typeOf(forCapture.reference);
        } else if (nestedScope != null &&
            nestedScope.originalIndexForVariable.containsKey(used)) {
          // The type inference algorithms treats variables as equal if they
          // have the same logical index. The index of variables might change
          // after applying the nested query transformer though, so we look up
          // the original index used during type inference.
          final originalIndex = nestedScope.originalIndexForVariable[used]!;
          final type = ctx.types2.session.typeOfVariable(originalIndex);
          internalType =
              type != null ? ResolveResult(type) : ResolveResult.unknown();
        } else {
          internalType = ctx.typeOf(used);
        }

        final type = driver.typeMapping.sqlTypeToDrift(internalType.type);

        if (forCapture != null) {
          addNewElement(FoundVariable.nestedQuery(
            index: currentIndex,
            name: name,
            sqlType: type,
            variable: used,
            forCaptured: forCapture,
          ));

          continue;
        }

        final isArray = internalType.type?.isArray ?? false;
        final isRequired = required.requiredNamedVariables.contains(name) ||
            required.requiredNumberedVariables.contains(used.resolvedIndex);

        if (explicitIndex != null && currentIndex >= maxIndex) {
          lints.add(AnalysisError(
            type: AnalysisErrorType.other,
            relevantNode: used,
            message: 'Cannot have have a variable with an index lower than '
                'that of an array appearing after an array!',
          ));
        }

        AppliedTypeConverter? converter;

        // Recognizing type converters on variables is opt-in since it would
        // break existing code.
        if (driver.options.applyConvertersOnVariables) {
          if (internalType.type?.hint<TypeConverterHint>()
              case final TypeConverterHint h) {
            converter = h.converter;
          }
        }

        addNewElement(FoundVariable(
          index: currentIndex,
          name: name,
          sqlType: type,
          nullable: internalType.type?.nullable ?? false,
          variable: used,
          isArray: isArray,
          typeConverter: converter,
          isRequired: isRequired,
        ));

        // arrays cannot be indexed explicitly because they're expanded into
        // multiple variables when executed
        if (isArray && explicitIndex != null) {
          lints.add(AnalysisError(
            type: AnalysisErrorType.other,
            message: 'Cannot use an array variable with an explicit index',
            relevantNode: used,
          ));
        }
        if (isArray) {
          maxIndex = used.resolvedIndex!;
        }
      } else if (used is DartPlaceholder) {
        // we don't what index this placeholder has, so we can't allow _any_
        // explicitly indexed variables coming after this
        maxIndex = 0;
        addNewElement(_extractPlaceholder(ctx, used));
      }
    }
    return (foundElements, references);
  }

  FoundDartPlaceholder _extractPlaceholder(
      AnalysisContext context, DartPlaceholder placeholder) {
    final name = placeholder.name;

    final type = placeholder.when(
      isExpression: (e) {
        final foundType = context.typeOf(e);
        ColumnType? columnType;
        if (foundType.type != null) {
          columnType = driver.typeMapping.sqlTypeToDrift(foundType.type);
        }

        final defaultValue =
            context.stmtOptions.defaultValuesForPlaceholder[name];

        return ExpressionDartPlaceholderType(columnType, defaultValue);
      },
      isLimit: (_) =>
          SimpleDartPlaceholderType(SimpleDartPlaceholderKind.limit),
      isOrderBy: (_) =>
          SimpleDartPlaceholderType(SimpleDartPlaceholderKind.orderBy),
      isOrderingTerm: (_) =>
          SimpleDartPlaceholderType(SimpleDartPlaceholderKind.orderByTerm),
      isInsertable: (_) {
        final insert = placeholder.parents.whereType<InsertStatement>().first;
        final table = insert.table.resultSet;

        return InsertableDartPlaceholderType(
            table is Table ? _lookupReference(table.name) as DriftTable : null);
      },
    );

    final availableResults = placeholder.statementScope.allAvailableResultSets;
    final availableDriftResults = <AvailableDriftResultSet>[];
    for (final available in availableResults) {
      final aliasedResultSet = available.resultSet.resultSet;
      final resultSet = aliasedResultSet?.unalias();
      String name;
      if (aliasedResultSet is NamedResultSet) {
        name = aliasedResultSet.name;
      } else {
        // If we don't have a name we can't include this result set.
        continue;
      }

      DriftElementWithResultSet driftEntity;

      if (resultSet is Table || resultSet is View) {
        driftEntity = _lookupReference((resultSet as NamedResultSet).name)
            as DriftElementWithResultSet;
      } else {
        // If this result set is an inner select statement or anything else we
        // can't represent it in Dart.
        continue;
      }

      availableDriftResults
          .add(AvailableDriftResultSet(name, driftEntity, available));
    }

    return FoundDartPlaceholder(type!, name, availableDriftResults)
      ..astNode = placeholder;
  }

  /// Merges [vars] and [placeholders] into a list that satisfies the order
  /// described in [_extractElements].
  List<dynamic /* Variable|DartPlaceholder */ > _mergeVarsAndPlaceholders(
      List<Variable> vars, List<DartPlaceholder> placeholders) {
    final groupVarsByIndex = <int, List<Variable>>{};
    for (final variable in vars) {
      groupVarsByIndex
          .putIfAbsent(variable.resolvedIndex!, () => [])
          .add(variable);
    }
    // sort each group by index
    for (final group in groupVarsByIndex.values) {
      group.sort((a, b) => a.resolvedIndex!.compareTo(b.resolvedIndex!));
    }

    late int Function(dynamic, dynamic) comparer;
    comparer = (dynamic a, dynamic b) {
      if (a is Variable && b is Variable) {
        // variables are sorted by their index
        return a.resolvedIndex!.compareTo(b.resolvedIndex!);
      } else if (a is DartPlaceholder && b is DartPlaceholder) {
        // placeholders by their position
        return AnalysisContext.compareNodesByOrder(a, b);
      } else {
        // ok, one of them is a variable, the other one is a placeholder. Let's
        // assume a is the variable. If not, we just switch results.
        if (a is Variable) {
          final placeholderB = b as DartPlaceholder;
          final firstWithSameIndex = groupVarsByIndex[a.resolvedIndex]!.first;

          return firstWithSameIndex.firstPosition
              .compareTo(placeholderB.firstPosition);
        } else {
          return -comparer(b, a);
        }
      }
    };

    final list = vars.cast<dynamic>().followedBy(placeholders).toList();
    return list..sort(comparer);
  }

  /// We verify that no variable numbers are skipped in the query. For instance,
  /// `SELECT * FROM tbl WHERE a = ?2 AND b = ?` would fail this check because
  /// the index 1 is never used.
  void _verifyNoSkippedIndexes(List<FoundElement> foundElements) {
    final variables = List.of(foundElements.whereType<FoundVariable>())
      ..sort((a, b) => a.index.compareTo(b.index));

    var currentExpectedIndex = 1;

    for (var i = 0; i < variables.length; i++) {
      final current = variables[i];
      if (current.index > currentExpectedIndex) {
        lints.add(
          AnalysisError(
            type: AnalysisErrorType.other,
            message:
                'Illegal variable index ${current.index} because no variable '
                'at index $currentExpectedIndex exists.',
            relevantNode: current.syntacticOrigin,
          ),
        );
      }

      if (i < variables.length - 1) {
        final next = variables[i + 1];
        if (next.index > currentExpectedIndex) {
          // if the next variable has a higher index, increment expected index
          // by one because we expect that every index is present
          currentExpectedIndex++;
        }
      }
    }
  }
}

/// Finds variables, Dart placeholders and outgoing references from nested
/// queries (which are eventually turned into variables) inside a query.
///
/// Nested children of this query are ignored, see `nested_queries.dart` for
/// details on nested queries and how they're implemented.
class _FindElements extends RecursiveVisitor<NestedQueriesContainer?, void> {
  final List<Variable> variables = [];
  final List<DartPlaceholder> dartPlaceholders = [];

  @override
  void visitVariable(Variable e, NestedQueriesContainer? arg) {
    variables.add(e);
    super.visitVariable(e, arg);
  }

  @override
  void visitDriftSpecificNode(
      DriftSpecificNode e, NestedQueriesContainer? arg) {
    if (e is NestedQueryColumn) {
      // If the node ist a nested query, return to avoid collecting elements
      // inside of it
      return;
    }

    if (e is DartPlaceholder) {
      dartPlaceholders.add(e);
    }

    super.visitDriftSpecificNode(e, arg);
  }

  @override
  void visitReference(Reference e, NestedQueriesContainer? arg) {
    if (arg is NestedQuery) {
      final captured = arg.capturedVariables[e];
      if (captured != null) {
        variables.add(captured.introducedVariable);
      }
    }

    super.visitReference(e, arg);
  }
}
