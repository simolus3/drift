import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:sqlparser/sqlparser.dart' hide ResultColumn;

import 'affected_tables_visitor.dart';

class QueryHandler {
  final String name;
  final AnalysisContext context;
  final TypeMapper mapper;

  Set<Table> _foundTables;
  List<FoundVariable> _foundVariables;

  SelectStatement get _select => context.root as SelectStatement;

  QueryHandler(this.name, this.context, this.mapper);

  SqlQuery handle() {
    final root = context.root;
    _foundVariables = mapper.extractVariables(context);

    if (root is SelectStatement) {
      return _handleSelect();
    } else if (root is UpdateStatement || root is DeleteStatement) {
      return _handleUpdate();
    } else {
      throw StateError(
          'Unexpected sql: Got $root, expected a select statement');
    }
  }

  UpdatingQuery _handleUpdate() {
    final updatedFinder = UpdatedTablesVisitor();
    context.root.accept(updatedFinder);
    _foundTables = updatedFinder.foundTables;

    return UpdatingQuery(name, context, _foundVariables,
        _foundTables.map(mapper.tableToMoor).toList());
  }

  SqlSelectQuery _handleSelect() {
    final tableFinder = ReferencedTablesVisitor();
    _select.accept(tableFinder);
    _foundTables = tableFinder.foundTables;
    final moorTables = _foundTables.map(mapper.tableToMoor).toList();

    return SqlSelectQuery(
        name, context, _foundVariables, moorTables, _inferResultSet());
  }

  InferredResultSet _inferResultSet() {
    final candidatesForSingleTable = Set.of(_foundTables);
    final columns = <ResultColumn>[];
    final rawColumns = _select.resolvedColumns;

    for (var column in rawColumns) {
      final type = context.typeOf(column).type;
      final moorType = mapper.resolvedToMoor(type);

      columns.add(ResultColumn(column.name, moorType, type.nullable));

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
}
