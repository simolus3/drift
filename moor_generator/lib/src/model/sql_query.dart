import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

final _illegalChars = RegExp(r'[^0-9a-zA-Z_]');
final _leadingDigits = RegExp(r'^\d*');

/// Represents the declaration of a compile-time query that will be analyzed
/// by moor_generator.
///
/// The subclasses [DeclaredDartQuery] and [DeclaredMoorQuery] contain
/// information about the declared statement, only the name is common for both
/// declaration methods.
/// In the `analyze` step, a [DeclaredQuery] is turned into a resolved
/// [SqlQuery], which contains information about the affected tables and what
/// columns are returned.
abstract class DeclaredQuery {
  final String name;

  DeclaredQuery(this.name);
}

/// A [DeclaredQuery] parsed from a Dart file by reading a constant annotation.
class DeclaredDartQuery extends DeclaredQuery {
  final String sql;

  DeclaredDartQuery(String name, this.sql) : super(name);
}

/// A [DeclaredQuery] read from a `.moor` file, where the AST is already
/// available.
class DeclaredMoorQuery extends DeclaredQuery {
  final AstNode query;

  DeclaredMoorQuery(String name, this.query) : super(name);

  factory DeclaredMoorQuery.fromStatement(DeclaredStatement stmt) {
    final name = stmt.name;
    final query = stmt.statement;
    return DeclaredMoorQuery(name, query);
  }
}

abstract class SqlQuery {
  final String name;
  final AnalysisContext fromContext;
  List<AnalysisError> lints;

  /// Whether this query was declared in a `.moor` file.
  ///
  /// For those kind of queries, we don't generate `get` and `watch` methods and
  /// instead only generate a single method returning a selectable.
  bool declaredInMoorFile = false;

  String get sql => fromContext.sql;

  /// The variables that appear in the [sql] query. We support three kinds of
  /// sql variables: The regular "?" variables, explicitly indexed "?xyz"
  /// variables and colon-named variables. Even though this feature is not
  /// supported by sqlite directly, we provide syntax sugar for expressions like
  /// `column IN ?`, where the variable will have a [List] type at runtime and
  /// expand to the appropriate tuple (e.g. `column IN (?, ?, ?)` when the
  /// variable is bound to a list with three elements). To make the desugaring
  /// easier at runtime, we require that:
  ///
  /// 1. Array arguments don't have an explicit index (`<expr> IN ?1` is
  ///    forbidden). The reason is that arrays get expanded to multiple
  ///    variables at runtime, so setting an explicit index doesn't make sense.
  /// 2. We only allow explicitly-indexed variables to appear after an array
  ///    if their index is lower than that of the array (e.g `a = ?2 AND b IN ?
  ///    AND c IN ?1`. In other words, we can expand an array without worrying
  ///    about the variables that appear after that array.
  final List<FoundVariable> variables;

  SqlQuery(this.name, this.fromContext, this.variables);
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

  SqlSelectQuery(String name, AnalysisContext fromContext,
      List<FoundVariable> variables, this.readsFrom, this.resultSet)
      : super(name, fromContext, variables);
}

class UpdatingQuery extends SqlQuery {
  final List<SpecifiedTable> updates;
  final bool isInsert;

  UpdatingQuery(String name, AnalysisContext fromContext,
      List<FoundVariable> variables, this.updates,
      {this.isInsert = false})
      : super(name, fromContext, variables);
}

class InferredResultSet {
  /// If the result columns of a SELECT statement exactly match one table, we
  /// can just use the data class generated for that table. Otherwise, we'd have
  /// to create another class.
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

  final UsedTypeConverter converter;

  ResultColumn(this.name, this.type, this.nullable, {this.converter});
}

/// A semantic interpretation of a [Variable] in a sql statement.
class FoundVariable {
  /// The (unique) index of this variable in the sql query. For instance, the
  /// query `SELECT * FROM tbl WHERE a = ? AND b = :xyz OR c = :xyz` contains
  /// three [Variable]s in its AST, but only two [FoundVariable]s, where the
  /// `?` will have index 1 and (both) `:xyz` variables will have index 2.
  int index;

  /// The name of this variable, or null if it's not a named variable.
  String name;

  /// The (inferred) type for this variable.
  final ColumnType type;

  /// The first [Variable] in the sql statement that has this [index].
  // todo: Do we really need to expose this? We only use [resolvedIndex], which
  // should always be equal to [index].
  final Variable variable;

  /// Whether this variable is an array, which will be expanded into multiple
  /// variables at runtime. We only accept queries where no explicitly numbered
  /// vars appear after an array. This means that we can expand array variables
  /// without having to look at other variables.
  final bool isArray;

  FoundVariable(this.index, this.name, this.type, this.variable, this.isArray) {
    assert(variable.resolvedIndex == index);
  }

  String get dartParameterName {
    if (name != null) {
      return name.replaceAll(_illegalChars, '');
    } else {
      return 'var${variable.resolvedIndex}';
    }
  }
}
