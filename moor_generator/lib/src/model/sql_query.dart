import 'package:moor/moor.dart' show UpdateKind;
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/utils/hash.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import 'column.dart';
import 'table.dart';
import 'used_type_converter.dart';

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
  final DeclaredStatement astNode;
  CrudStatement get query => astNode.statement;
  ParsedMoorFile file;

  DeclaredMoorQuery(String name, this.astNode) : super(name);

  factory DeclaredMoorQuery.fromStatement(DeclaredStatement stmt) {
    assert(stmt.identifier is SimpleName);
    final name = (stmt.identifier as SimpleName).name;
    return DeclaredMoorQuery(name, stmt);
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
  List<FoundVariable> variables;

  /// The placeholders in this query which are bound and converted to sql at
  /// runtime. For instance, in `SELECT * FROM tbl WHERE $expr`, the `expr` is
  /// going to be a [FoundDartPlaceholder] with the type
  /// [DartPlaceholderType.expression] and [ColumnType.boolean]. We will
  /// generate a method which has a `Expression<bool, BoolType> expr` parameter.
  List<FoundDartPlaceholder> placeholders;

  /// Union of [variables] and [elements], but in the order in which they
  /// appear inside the query.
  final List<FoundElement> elements;

  /// Whether the underlying sql statement of this query operates on more than
  /// one table. In that case, column references in Dart placeholders have to
  /// write their table name (e.g. `foo.bar` instead of just `bar`).
  final bool hasMultipleTables;

  SqlQuery(this.name, this.fromContext, this.elements, {bool hasMultipleTables})
      : hasMultipleTables = hasMultipleTables ?? false {
    variables = elements.whereType<FoundVariable>().toList();
    placeholders = elements.whereType<FoundDartPlaceholder>().toList();
  }
}

class SqlSelectQuery extends SqlQuery {
  final List<MoorTable> readsFrom;
  final InferredResultSet resultSet;

  String get resultClassName {
    if (resultSet.matchingTable != null) {
      return resultSet.matchingTable.dartTypeName;
    }

    if (resultSet.singleColumn) {
      return resultSet.columns.single.dartType;
    }

    return '${ReCase(name).pascalCase}Result';
  }

  SqlSelectQuery(
    String name,
    AnalysisContext fromContext,
    List<FoundElement> elements,
    this.readsFrom,
    this.resultSet,
  ) : super(name, fromContext, elements,
            hasMultipleTables: readsFrom.length > 1);
}

class UpdatingQuery extends SqlQuery {
  final List<WrittenMoorTable> updates;
  final bool isInsert;

  bool get isOnlyDelete => updates.every((w) => w.kind == UpdateKind.delete);
  bool get isOnlyUpdate => updates.every((w) => w.kind == UpdateKind.update);

  UpdatingQuery(String name, AnalysisContext fromContext,
      List<FoundElement> elements, this.updates,
      {this.isInsert = false, bool hasMultipleTables})
      : super(name, fromContext, elements,
            hasMultipleTables: hasMultipleTables);
}

class InferredResultSet {
  /// If the result columns of a SELECT statement exactly match one table, we
  /// can just use the data class generated for that table. Otherwise, we'd have
  /// to create another class.
  final MoorTable /*?*/ matchingTable;

  /// Tables in the result set that should appear as a class.
  ///
  /// See [NestedResultTable] for further discussion and examples.
  final List<NestedResultTable> nestedResults;

  final List<ResultColumn> columns;
  final Map<ResultColumn, String> _dartNames = {};

  InferredResultSet(this.matchingTable, this.columns,
      {this.nestedResults = const []});

  /// Whether a new class needs to be written to store the result of this query.
  /// We don't need to do that for queries which return an existing table model
  /// or if they only return exactly one column.
  bool get needsOwnClass => matchingTable == null && columns.length > 1;

  /// Whether this query returns a single column that should be returned
  /// directly.
  bool get singleColumn =>
      matchingTable == null && nestedResults.isEmpty && columns.length == 1;

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

  /// The dart type that can store a result of this column.
  String get dartType {
    if (converter != null) {
      return converter.mappedType.getDisplayString();
    } else {
      return dartTypeNames[type];
    }
  }
}

/// A nested table extracted from a `**` column.
///
/// For instance, consider this query:
/// ```sql
/// CREATE TABLE groups (id INTEGER NOT NULL PRIMARY KEY);
/// CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY);
/// CREATE TABLE members (
///   group INT REFERENCES ..,
///   user INT REFERENCES ...,
///   is_admin BOOLEAN
/// );
///
/// membersOf: SELECT users.**, members.is_admin FROM members
///   INNER JOIN users ON users.id = members.user;
/// ```
///
/// The generated result set should now look like this:
/// ```dart
/// class MembersOfResult {
///   final User users;
///   final bool isAdmin;
/// }
/// ```
///
/// Knowing that `User` should be extracted into a field is represented with a
/// [NestedResultTable] information as part of the result set.
class NestedResultTable {
  final NestedStarResultColumn from;
  final String name;
  final MoorTable table;

  NestedResultTable(this.from, this.name, this.table);

  String get dartFieldName => ReCase(name).camelCase;
}

/// Something in the query that needs special attention when generating code,
/// such as variables or Dart placeholders.
abstract class FoundElement {
  String get dartParameterName;

  /// The type of this element on the generated method.
  String get parameterType;
}

/// A semantic interpretation of a [Variable] in a sql statement.
class FoundVariable extends FoundElement {
  /// The (unique) index of this variable in the sql query. For instance, the
  /// query `SELECT * FROM tbl WHERE a = ? AND b = :xyz OR c = :xyz` contains
  /// three [Variable]s in its AST, but only two [FoundVariable]s, where the
  /// `?` will have index 1 and (both) `:xyz` variables will have index 2. We
  /// only report one [FoundVariable] per index.
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

  FoundVariable(this.index, this.name, this.type, this.variable, this.isArray)
      : assert(variable.resolvedIndex == index);

  @override
  String get dartParameterName {
    if (name != null) {
      return name.replaceAll(_illegalChars, '');
    } else {
      return 'var${variable.resolvedIndex}';
    }
  }

  @override
  String get parameterType {
    final innerType = dartTypeNames[type] ?? 'dynamic';
    if (isArray) {
      return 'List<$innerType>';
    }
    return innerType;
  }
}

enum DartPlaceholderType {
  expression,
  limit,
  orderByTerm,
  orderBy,
}

/// A Dart placeholder that will be bound at runtime.
class FoundDartPlaceholder extends FoundElement {
  final DartPlaceholderType type;

  /// If [type] is [DartPlaceholderType.expression] and the expression could be
  /// resolved, this is the type of that expression.
  final ColumnType columnType;

  final String name;
  DartPlaceholder astNode;

  FoundDartPlaceholder(this.type, this.columnType, this.name);

  @override
  String get parameterType {
    switch (type) {
      case DartPlaceholderType.expression:
        if (columnType == null) return 'Expression';

        final dartType = dartTypeNames[columnType];
        return 'Expression<$dartType>';
        break;
      case DartPlaceholderType.limit:
        return 'Limit';
      case DartPlaceholderType.orderByTerm:
        return 'OrderingTerm';
      case DartPlaceholderType.orderBy:
        return 'OrderBy';
    }

    throw AssertionError('cant happen, all branches covered');
  }

  @override
  String get dartParameterName => name;

  @override
  int get hashCode => hashAll([type, columnType, name]);

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        other is FoundDartPlaceholder &&
            other.type == type &&
            other.columnType == columnType &&
            other.name == name;
  }
}
