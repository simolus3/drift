import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:recase/recase.dart';

final _illegalChars = RegExp(r'[^0-9a-zA-Z_]');
final _leadingDigits = RegExp(r'^\d*');

abstract class SqlQuery {
  final String name;
  final String sql;
  final List<FoundVariable> variables;

  SqlQuery(this.name, this.sql, this.variables);
}

class SqlSelectQuery extends SqlQuery {
  final List<SpecifiedTable> readsFrom;
  final InferredResultSet resultSet;

  String get resultClassName {
    if (resultSet.matchingTable != null) {
      return resultSet.matchingTable.dartTypeName;
    }
    return '${ReCase(name).pascalCase}Result';
  }

  SqlSelectQuery(String name, String sql, List<FoundVariable> variables,
      this.readsFrom, this.resultSet)
      : super(name, sql, variables);
}

class InferredResultSet {
  /// If the result columns of a SELECT statement exactly match one table, we
  /// can just use the data class generated for that table. Otherwise, we'd have
  /// to create another class.
  // todo implement this check
  final SpecifiedTable matchingTable;
  final List<ResultColumn> columns;
  final Map<ResultColumn, String> _dartNames = {};

  InferredResultSet(this.matchingTable, this.columns);

  void forceDartNames(Map<ResultColumn, String> names) {
    _dartNames
      ..clear()
      ..addAll(names);
  }

  /// Suggests an appropriate name that can be used as a dart field.
  String dartNameFor(ResultColumn column) {
    return _dartNames.putIfAbsent(column, () {
      // remove chars which cannot appear in dart identifiers, also strip away
      // leading digits
      var name = column.name
          .replaceAll(_illegalChars, '')
          .replaceFirst(_leadingDigits, '');

      if (name.isEmpty) {
        name = 'empty';
      }

      name = ReCase(name).camelCase;

      return _appendNumbersIfExists(name);
    });
  }

  String _appendNumbersIfExists(String name) {
    final originalName = name;
    var counter = 1;
    while (_dartNames.values.contains(name)) {
      name = originalName + counter.toString();
      counter++;
    }
    return name;
  }
}

class ResultColumn {
  final String name;
  final ColumnType type;
  final bool nullable;

  ResultColumn(this.name, this.type, this.nullable);
}

class FoundVariable {
  int index;
  String name;
  final ColumnType type;

  FoundVariable(this.index, this.name, this.type);

  String get dartParameterName =>
      name?.replaceAll(_illegalChars, '') ?? 'var$index';
}
