import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/utils/type_converter_hint.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

import 'affected_tables_visitor.dart';
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

    final linter = Linter(this);
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
      throw StateError(
          'Unexpected sql: Got $root, expected insert, select, update or delete');
    }
  }

  UpdatingQuery _handleUpdate() {
    final updatedFinder = UpdatedTablesVisitor();
    context.root.accept(updatedFinder);
    _foundTables = updatedFinder.foundTables;

    final isInsert = context.root is InsertStatement;

    return UpdatingQuery(name, context, _foundElements,
        _foundTables.map(mapper.tableToMoor).toList(),
        isInsert: isInsert);
  }

  SqlSelectQuery _handleSelect() {
    final tableFinder = ReferencedTablesVisitor();
    _select.accept(tableFinder);
    _foundTables = tableFinder.foundTables;
    final moorTables = _foundTables.map(mapper.tableToMoor).toList();

    return SqlSelectQuery(
        name, context, _foundElements, moorTables, _inferResultSet());
  }

  InferredResultSet _inferResultSet() {
    final candidatesForSingleTable = Set.of(_foundTables);
    final columns = <ResultColumn>[];
    final rawColumns = _select.resolvedColumns;

    for (var column in rawColumns) {
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

    // if all columns read from the same table, and all columns in that table
    // are present in the result set, we can use the data class we generate for
    // that table instead of generating another class just for this result set.
    if (candidatesForSingleTable.length == 1) {
      final table = candidatesForSingleTable.single;
      final moorTable = mapper.tableToMoor(table);

      final resultEntryToColumn = <ResultColumn, String>{};
      var matches = true;

      // go trough all columns of the table in question
      for (var column in moorTable.columns) {
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
      if (resultEntryToColumn.length != moorTable.columns.length) {
        matches = false;
      }

      if (matches) {
        return InferredResultSet(moorTable, columns)
          ..forceDartNames(resultEntryToColumn);
      }
    }

    return InferredResultSet(null, columns);
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
        return expression.resolved as TableColumn;
      }
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
