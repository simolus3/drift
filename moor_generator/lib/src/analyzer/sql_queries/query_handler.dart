import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/utils/type_converter_hint.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;
import 'package:sqlparser/utils/find_referenced_tables.dart';

import 'lints/linter.dart';

/// Maps an [AnalysisContext] from the sqlparser to a [SqlQuery] from this
/// generator package by determining its type, return columns, variables and so
/// on.
class QueryHandler {
  final String name;
  final AnalysisContext context;
  final TypeMapper mapper;

  Set<Table> _foundTables;
  List<FoundElement> _foundElements;
  Iterable<FoundVariable> get _foundVariables =>
      _foundElements.whereType<FoundVariable>();

  BaseSelectStatement get _select => context.root as BaseSelectStatement;

  QueryHandler(this.name, this.context, this.mapper);

  SqlQuery handle() {
    _foundElements = mapper.extractElements(context);

    _verifyNoSkippedIndexes();
    final query = _mapToMoor();

    final linter = Linter.forHandler(this);
    linter.reportLints();
    query.lints = linter.lints;

    return query;
  }

  SqlQuery _mapToMoor() {
    final root = context.root;
    if (root is BaseSelectStatement) {
      return _handleSelect();
    } else if (root is UpdateStatement ||
        root is DeleteStatement ||
        root is InsertStatement) {
      return _handleUpdate();
    } else {
      throw StateError('Unexpected sql: Got $root, expected insert, select, '
          'update or delete');
    }
  }

  UpdatingQuery _handleUpdate() {
    final updatedFinder = UpdatedTablesVisitor();
    context.root.acceptWithoutArg(updatedFinder);
    _foundTables = updatedFinder.writtenTables.map((w) => w.table).toSet();

    final isInsert = context.root is InsertStatement;

    return UpdatingQuery(
      name,
      context,
      _foundElements,
      updatedFinder.writtenTables.map(mapper.writtenToMoor).toList(),
      isInsert: isInsert,
      hasMultipleTables: updatedFinder.foundTables.length > 1,
    );
  }

  SqlSelectQuery _handleSelect() {
    final tableFinder = ReferencedTablesVisitor();
    _select.acceptWithoutArg(tableFinder);
    _foundTables = tableFinder.foundTables;
    final moorTables =
        _foundTables.map(mapper.tableToMoor).where((s) => s != null).toList();

    return SqlSelectQuery(
        name, context, _foundElements, moorTables, _inferResultSet());
  }

  InferredResultSet _inferResultSet() {
    final candidatesForSingleTable = Set.of(_foundTables);
    final columns = <ResultColumn>[];
    final rawColumns = _select.resolvedColumns;

    // First, go through regular result columns
    for (final column in rawColumns) {
      final type = context.typeOf(column).type;
      final moorType = mapper.resolvedToMoor(type);
      UsedTypeConverter converter;
      if (type?.hint is TypeConverterHint) {
        converter = (type.hint as TypeConverterHint).converter;
      }

      columns.add(ResultColumn(column.name, moorType, type?.nullable ?? true,
          converter: converter));

      final table = _tableOfColumn(column);
      candidatesForSingleTable.removeWhere((t) => t != table);
    }

    final nestedResults = _findNestedResultTables();
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
      final moorTable = mapper.tableToMoor(table);

      if (moorTable == null) {
        // References a table not declared in any moor api (dart or moor file).
        // This can happen for internal sqlite tables
        return InferredResultSet(null, columns);
      }

      final resultEntryToColumn = <ResultColumn, String>{};
      var matches = true;

      // go trough all columns of the table in question
      for (final column in moorTable.columns) {
        // check if this column from the table is present in the result set
        final tableColumn = table.findColumn(column.name.name);
        final inResultSet =
            rawColumns.where((t) => _toTableColumn(t) == tableColumn);

        if (inResultSet.length == 1) {
          // it is! Remember the correct getter name from the data class for
          // later when we write the mapping code.
          final columnIndex = rawColumns.indexOf(inResultSet.single);
          resultEntryToColumn[columns[columnIndex]] = column.dartGetterName;
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
        return InferredResultSet(moorTable, columns)
          ..forceDartNames(resultEntryToColumn);
      }
    }

    return InferredResultSet(null, columns, nestedResults: nestedResults);
  }

  List<NestedResultTable> _findNestedResultTables() {
    final query = _select;
    // We don't currently support nested results for compound statements
    if (query is! SelectStatement) return const [];

    final nestedTables = <NestedResultTable>[];

    for (final column in (query as SelectStatement).columns) {
      if (column is NestedStarResultColumn) {
        final result = column.resultSet;
        if (result is! Table) continue;

        final moorTable = mapper.tableToMoor(result as Table);
        nestedTables
            .add(NestedResultTable(column, column.tableName, moorTable));
      }
    }

    return nestedTables;
  }

  /// The table a given result column is from, or null if this column doesn't
  /// read from a table directly.
  Table _tableOfColumn(Column c) {
    return _toTableColumn(c)?.table;
  }

  TableColumn _toTableColumn(Column c) {
    if (c is TableColumn) {
      return c;
    } else if (c is ExpressionColumn) {
      final expression = c.expression;
      if (expression is Reference) {
        final resolved = expression.resolved;
        if (resolved is Column) {
          return _toTableColumn(resolved);
        }
      }
    } else if (c is DelegatedColumn) {
      return _toTableColumn(c.innerColumn);
    }
    return null;
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
