import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:drift_dev/src/utils/type_converter_hint.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:sqlparser/utils/find_referenced_tables.dart';

import 'lints/linter.dart';
import 'required_variables.dart';

/// Maps an [AnalysisContext] from the sqlparser to a [SqlQuery] from this
/// generator package by determining its type, return columns, variables and so
/// on.
class QueryHandler {
  final AnalysisContext context;
  final TypeMapper mapper;
  final RequiredVariables requiredVariables;

  late Set<Table> _foundTables;
  late Set<View> _foundViews;
  late List<FoundElement> _foundElements;

  Iterable<FoundVariable> get _foundVariables =>
      _foundElements.whereType<FoundVariable>();

  QueryHandler(
    this.context,
    this.mapper, {
    this.requiredVariables = RequiredVariables.empty,
  });

  SqlQuery handle(DeclaredQuery source) {
    _foundElements =
        mapper.extractElements(context, required: requiredVariables);

    _verifyNoSkippedIndexes();

    final String? requestedResultClass;
    if (source is DeclaredMoorQuery) {
      requestedResultClass = source.astNode.as;
    } else {
      requestedResultClass = null;
    }

    final query = _mapToMoor(
      queryName: source.name,
      requestedResultClass: requestedResultClass,
      root: context.root,
    );

    final linter = Linter.forHandler(this);
    linter.reportLints();
    query.lints = linter.lints;

    return query;
  }

  SqlQuery _mapToMoor({
    required String queryName,
    required String? requestedResultClass,
    required AstNode root,
  }) {
    if (root is BaseSelectStatement) {
      return _handleSelect(
        queryName: queryName,
        requestedResultClass: requestedResultClass,
        select: root,
      );
    } else if (root is UpdateStatement ||
        root is DeleteStatement ||
        root is InsertStatement) {
      return _handleUpdate(queryName, root);
    } else {
      throw StateError('Unexpected sql: Got $root, expected insert, select, '
          'update or delete');
    }
  }

  void _applyFoundTables(ReferencedTablesVisitor visitor) {
    _foundTables = visitor.foundTables;
    _foundViews = visitor.foundViews;
  }

  UpdatingQuery _handleUpdate(String queryName, AstNode root) {
    final updatedFinder = UpdatedTablesVisitor();
    root.acceptWithoutArg(updatedFinder);
    _applyFoundTables(updatedFinder);

    final isInsert = root is InsertStatement;

    InferredResultSet? resultSet;
    if (root is StatementReturningColumns) {
      final columns = root.returnedResultSet?.resolvedColumns;
      if (columns != null) {
        resultSet = _inferResultSet(root, columns);
      }
    }

    return UpdatingQuery(
      queryName,
      context,
      root,
      _foundElements,
      updatedFinder.writtenTables
          .map(mapper.writtenToMoor)
          .whereType<WrittenMoorTable>()
          .toList(),
      isInsert: isInsert,
      hasMultipleTables: updatedFinder.foundTables.length > 1,
      resultSet: resultSet,
    );
  }

  SqlSelectQuery _handleSelect({
    required String queryName,
    required String? requestedResultClass,
    required BaseSelectStatement select,
  }) {
    final tableFinder = ReferencedTablesVisitor();
    select.acceptWithoutArg(tableFinder);
    // fine
    _applyFoundTables(tableFinder);

    final moorTables =
        _foundTables.map(mapper.tableToMoor).whereType<MoorTable>().toList();
    final moorViews =
        _foundViews.map(mapper.viewToMoor).whereType<MoorView>().toList();

    final moorEntities = [...moorTables, ...moorViews];

    return SqlSelectQuery(
      queryName,
      context,
      select,
      _foundElements,
      moorEntities,
      _inferResultSet(select, select.resolvedColumns!),
      requestedResultClass,
    );
  }

  InferredResultSet _inferResultSet(AstNode select, List<Column> rawColumns) {
    final candidatesForSingleTable = {..._foundTables, ..._foundViews};
    final columns = <ResultColumn>[];

    // First, go through regular result columns
    for (final column in rawColumns) {
      final type = context.typeOf(column).type;
      final moorType = mapper.resolvedToMoor(type);
      UsedTypeConverter? converter;
      if (type?.hint is TypeConverterHint) {
        converter = (type!.hint as TypeConverterHint).converter;
      }

      columns.add(ResultColumn(column.name, moorType, type?.nullable ?? true,
          typeConverter: converter, sqlParserColumn: column));

      final resultSet = _resultSetOfColumn(column);
      candidatesForSingleTable.removeWhere((t) => t != resultSet);
    }

    final nestedResults = _findNestedResultTables(select);
    if (nestedResults.isNotEmpty) {
      // The single table optimization doesn't make sense when nested result
      // sets are present.
      candidatesForSingleTable.clear();
    }

    // if all columns read from the same table, and all columns in that table
    // are present in the result set, we can use the data class we generate for
    // that table instead of generating another class just for this result set.
    if (candidatesForSingleTable.length == 1) {
      final table = candidatesForSingleTable.single;
      final moorTable = mapper.viewOrTableToMoor(table);

      if (moorTable == null) {
        // References a table not declared in any moor api (dart or moor file).
        // This can happen for internal sqlite tables
        return InferredResultSet(null, columns);
      }

      final resultEntryToColumn = <ResultColumn, String>{};
      final resultColumnNameToMoor = <String, MoorColumn>{};
      var matches = true;

      // go trough all columns of the table in question
      for (final column in moorTable.columns) {
        // check if this column from the table is present in the result set
        final tableColumn = table.findColumn(column.name.name);
        final inResultSet =
            rawColumns.where((t) => _toTableOrViewColumn(t) == tableColumn);

        if (inResultSet.length == 1) {
          // it is! Remember the correct getter name from the data class for
          // later when we write the mapping code.
          final columnIndex = rawColumns.indexOf(inResultSet.single);
          final resultColumn = columns[columnIndex];

          resultEntryToColumn[resultColumn] = column.dartGetterName;
          resultColumnNameToMoor[resultColumn.name] = column;
        } else {
          // it's not, so no match
          matches = false;
          break;
        }
      }

      // we have established that all columns in resultEntryToColumn do appear
      // in the moor table. Now check for set equality.
      if (rawColumns.length != moorTable.columns.length) {
        matches = false;
      }

      if (matches) {
        final match = MatchingMoorTable(moorTable, resultColumnNameToMoor);
        return InferredResultSet(match, columns)
          ..forceDartNames(resultEntryToColumn);
      }
    }

    return InferredResultSet(null, columns, nestedResults: nestedResults);
  }

  List<NestedResult> _findNestedResultTables(AstNode query) {
    // We don't currently support nested results for compound statements
    if (query is! SelectStatement) return const [];

    final nestedTables = <NestedResult>[];
    final analysis = JoinModel.of(query);

    for (final column in query.columns) {
      if (column is NestedStarResultColumn) {
        final originalResult = column.resultSet;
        final result = originalResult?.unalias();
        if (result is! Table && result is! View) continue;

        final moorTable = mapper.viewOrTableToMoor(result)!;
        final isNullable =
            analysis == null || analysis.isNullableTable(originalResult!);
        nestedTables.add(NestedResultTable(
          column,
          column.as ?? column.tableName,
          moorTable,
          isNullable: isNullable,
        ));
      } else if (column is NestedQueryColumn) {
        nestedTables.add(NestedResultQuery(
          from: column,
          query: _handleSelect(
            queryName: 'nested',
            requestedResultClass: column.as,
            select: column.select,
          ),
        ));
      }
    }

    return nestedTables;
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

  /// We verify that no variable numbers are skipped in the query. For instance,
  /// `SELECT * FROM tbl WHERE a = ?2 AND b = ?` would fail this check because
  /// the index 1 is never used.
  void _verifyNoSkippedIndexes() {
    final variables = List.of(_foundVariables)
      ..sort((a, b) => a.index.compareTo(b.index));

    var currentExpectedIndex = 1;

    for (var i = 0; i < variables.length; i++) {
      final current = variables[i];
      if (current.index > currentExpectedIndex) {
        throw StateError('This query skips some variable indexes: '
            'We found no variable is at position $currentExpectedIndex, '
            'even though a variable at index ${current.index} exists.');
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
