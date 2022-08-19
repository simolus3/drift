import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show UpdateKind;
import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/analyzer/sql_queries/nested_queries.dart';
import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import 'model.dart';

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
  ParsedDriftFile? file;

  DeclaredMoorQuery(String name, this.astNode) : super(name);

  List<CrudStatement> get query {
    final stmt = astNode.statement;
    if (stmt is CrudStatement) {
      return [stmt];
    } else if (stmt is TransactionBlock) {
      return stmt.innerStatements;
    } else {
      throw StateError('Invalid statement: $stmt');
    }
  }

  factory DeclaredMoorQuery.fromStatement(DeclaredStatement stmt) {
    assert(stmt.identifier is SimpleName);
    final name = (stmt.identifier as SimpleName).name;
    return DeclaredMoorQuery(name, stmt);
  }
}

abstract class SqlQuery {
  final String name;

  AnalysisContext? get fromContext;
  AstNode? get root;
  List<AnalysisError>? lints;

  /// Whether this query was declared in a `.moor` file.
  ///
  /// For those kind of queries, we don't generate `get` and `watch` methods and
  /// instead only generate a single method returning a selectable.
  bool declaredInMoorFile = false;

  String? get sql => fromContext?.sql;

  /// The result set of this statement, mapped to moor-generated classes.
  ///
  /// This is non-nullable for select queries. Updating queries might have a
  /// result set if they have a `RETURNING` clause.
  InferredResultSet? get resultSet;

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
  late List<FoundVariable> variables;

  /// The placeholders in this query which are bound and converted to sql at
  /// runtime. For instance, in `SELECT * FROM tbl WHERE $expr`, the `expr` is
  /// going to be a [FoundDartPlaceholder] with the type
  /// [ExpressionDartPlaceholderType] and [DriftSqlType.bool]. We will
  /// generate a method which has a `Expression<bool, BoolType> expr` parameter.
  late List<FoundDartPlaceholder> placeholders;

  /// Union of [variables] and [placeholders], but in the order in which they
  /// appear inside the query.
  final List<FoundElement> elements;

  /// Whether the underlying sql statement of this query operates on more than
  /// one table. In that case, column references in Dart placeholders have to
  /// write their table name (e.g. `foo.bar` instead of just `bar`).
  final bool hasMultipleTables;

  SqlQuery(this.name, this.elements, {bool? hasMultipleTables})
      : hasMultipleTables = hasMultipleTables ?? false {
    variables = elements.whereType<FoundVariable>().toList();
    placeholders = elements.whereType<FoundDartPlaceholder>().toList();
  }

  bool get needsAsyncMapping {
    final result = resultSet;
    if (result != null) {
      // Mapping to tables is asynchronous
      if (result.matchingTable != null) return true;
      if (result.nestedResults.any((e) => e is NestedResultTable)) return true;
    }

    return false;
  }

  String get resultClassName {
    final resultSet = this.resultSet;
    if (resultSet == null) {
      throw StateError('This query ($name) does not have a result set');
    }

    if (resultSet.matchingTable != null || resultSet.singleColumn) {
      throw UnsupportedError('This result set does not introduce a class, '
          'either because it has a matching table or because it only returns '
          'one column.');
    }

    return resultSet.resultClassName ?? '${ReCase(name).pascalCase}Result';
  }

  /// The Dart type representing a row of this result set.
  String resultTypeCode(
      [GenerationOptions options = const GenerationOptions()]) {
    final resultSet = this.resultSet;
    if (resultSet == null) {
      throw StateError('This query ($name) does not have a result set');
    }

    if (resultSet.matchingTable != null) {
      return resultSet.matchingTable!.table.dartTypeCode();
    }

    if (resultSet.singleColumn) {
      return resultSet.columns.single.dartTypeCode();
    }

    return resultClassName;
  }

  /// Returns all found elements, from this query an all nested queries. The
  /// elements returned by this method are in no particular order, thus they
  /// can only be used to determine the method parameters.
  ///
  /// This method makes some effort to remove duplicated parameters. But only
  /// by comparing the dart name.
  List<FoundElement> elementsWithNestedQueries() {
    final elements = List.of(this.elements);

    final subQueries = resultSet?.nestedResults.whereType<NestedResultQuery>();
    for (final subQuery in subQueries ?? const <NestedResultQuery>[]) {
      for (final subElement in subQuery.query.elementsWithNestedQueries()) {
        if (elements
            .none((e) => e.dartParameterName == subElement.dartParameterName)) {
          elements.add(subElement);
        }
      }
    }

    return elements;
  }
}

class SqlSelectQuery extends SqlQuery {
  final List<DriftSchemaEntity> readsFrom;
  @override
  final InferredResultSet resultSet;
  @override
  final AnalysisContext fromContext;
  @override
  final AstNode root;

  /// The name of the result class, as requested by the user.
  // todo: Allow custom result classes for RETURNING as well?
  final String? requestedResultClass;

  final NestedQueriesContainer? nestedContainer;

  /// Whether this query contains nested queries or not
  bool get hasNestedQuery =>
      resultSet.nestedResults.any((e) => e is NestedResultQuery);

  @override
  bool get needsAsyncMapping => hasNestedQuery || super.needsAsyncMapping;

  SqlSelectQuery(
    String name,
    this.fromContext,
    this.root,
    List<FoundElement> elements,
    this.readsFrom,
    this.resultSet,
    this.requestedResultClass,
    this.nestedContainer,
  ) : super(name, elements, hasMultipleTables: readsFrom.length > 1);

  Set<DriftTable> get readsFromTables {
    return {
      for (final entity in readsFrom)
        if (entity is DriftTable)
          entity
        else if (entity is MoorView)
          ...entity.transitiveTableReferences,
    };
  }

  /// Creates a copy of this [SqlSelectQuery] with a new [resultSet].
  ///
  /// The copy won't have a [requestedResultClass].
  SqlSelectQuery replaceResultSet(InferredResultSet resultSet) {
    return SqlSelectQuery(
      name,
      fromContext,
      root,
      elements,
      readsFrom,
      resultSet,
      null,
      nestedContainer,
    );
  }
}

/// Something that can contain nested queries.
///
/// This contains the root select statement and all nested queries that appear
/// in a nested queries container.
class NestedQueriesContainer {
  final SelectStatement select;
  final Map<NestedQueryColumn, NestedQuery> nestedQueries = {};

  NestedQueriesContainer(this.select);

  /// Columns that should be added to the [select] statement to read variables
  /// captured by children.
  ///
  /// These columns aren't mounted to the same syntax tree as [select], they
  /// will be mounted into the tree returned by [addHelperNodes].
  final List<ExpressionResultColumn> addedColumns = [];

  Iterable<CapturedVariable> get variablesCapturedByChildren {
    return nestedQueries.values
        .expand((nested) => nested.capturedVariables.values);
  }
}

/// A nested query found in a SQL statement.
///
/// See the `NestedQueryAnalyzer` for an overview on how nested queries work.
class NestedQuery extends NestedQueriesContainer {
  final NestedQueryColumn queryColumn;
  final NestedQueriesContainer parent;

  /// All references that read from a table only available in the outer
  /// select statement. It will need to be transformed in a later step.
  final Map<Reference, CapturedVariable> capturedVariables = {};

  NestedQuery(this.parent, this.queryColumn) : super(queryColumn.select);
}

class CapturedVariable {
  final Reference reference;

  /// A number uniquely identifying this captured variable in the select
  /// statement analyzed.
  ///
  /// This is used to add the necessary helper column later.
  final int queryGlobalId;

  /// The variable introduced to replace the original reference.
  ///
  /// This variable is not mounted to the same syntax tree as [reference], it
  /// will be mounted into the tree returned by [addHelperNodes].
  final ColonNamedVariable introducedVariable;

  String get helperColumn => '\$n_$queryGlobalId';

  CapturedVariable(this.reference, this.queryGlobalId)
      : introducedVariable = ColonNamedVariable.synthetic(':r$queryGlobalId') {
    introducedVariable.setMeta<CapturedVariable>(this);
  }
}

class UpdatingQuery extends SqlQuery {
  final List<WrittenMoorTable> updates;
  final bool isInsert;
  @override
  final InferredResultSet? resultSet;
  @override
  final AnalysisContext fromContext;
  @override
  final AstNode root;

  bool get isOnlyDelete => updates.every((w) => w.kind == UpdateKind.delete);

  bool get isOnlyUpdate => updates.every((w) => w.kind == UpdateKind.update);

  UpdatingQuery(
    String name,
    this.fromContext,
    this.root,
    List<FoundElement> elements,
    this.updates, {
    this.isInsert = false,
    bool? hasMultipleTables,
    this.resultSet,
  }) : super(name, elements, hasMultipleTables: hasMultipleTables);
}

/// A special kind of query running multiple inner queries in a transaction.
class InTransactionQuery extends SqlQuery {
  final List<SqlQuery> innerQueries;

  InTransactionQuery(this.innerQueries, String name)
      : super(name, [for (final query in innerQueries) ...query.elements]);

  @override
  InferredResultSet? get resultSet => null;

  @override
  AnalysisContext? get fromContext => null;

  @override
  AstNode? get root => null;
}

class InferredResultSet {
  /// If the result columns of a SELECT statement exactly match one table, we
  /// can just use the data class generated for that table. Otherwise, we'd have
  /// to create another class.
  final MatchingMoorTable? matchingTable;

  /// Tables in the result set that should appear as a class.
  ///
  /// See [NestedResult] for further discussion and examples.
  final List<NestedResult> nestedResults;
  Map<NestedResult, String>? _expandedNestedPrefixes;

  final List<ResultColumn> columns;
  final Map<ResultColumn, String> _dartNames = {};

  /// The name of the Dart class generated to store this result set, or null if
  /// it hasn't explicitly been set.
  final String? resultClassName;

  /// Explicitly controls that no result class should be generated for this
  /// result set.
  ///
  /// This is enabled on duplicate result sets caused by custom result class
  /// names.
  final bool dontGenerateResultClass;

  InferredResultSet(
    this.matchingTable,
    this.columns, {
    this.nestedResults = const [],
    this.resultClassName,
    this.dontGenerateResultClass = false,
  });

  /// Whether a new class needs to be written to store the result of this query.
  ///
  /// We don't need to introduce result classes for queries which
  /// - return an existing table model
  /// - return exactly one column
  ///
  /// We always need to generate a class if the query contains nested results.
  bool get needsOwnClass {
    return matchingTable == null &&
        (columns.length > 1 || nestedResults.isNotEmpty) &&
        !dontGenerateResultClass;
  }

  /// Whether this query returns a single column that should be returned
  /// directly.
  bool get singleColumn =>
      matchingTable == null && nestedResults.isEmpty && columns.length == 1;

  String? nestedPrefixFor(NestedResult table) {
    if (_expandedNestedPrefixes == null) {
      var index = 0;
      _expandedNestedPrefixes = {
        for (final nested in nestedResults) nested: 'nested_${index++}',
      };
    }

    return _expandedNestedPrefixes![table];
  }

  void forceDartNames(Map<ResultColumn, String> names) {
    _dartNames
      ..clear()
      ..addAll(names);
  }

  /// Suggests an appropriate name that can be used as a dart field for the
  /// [column].
  String dartNameFor(ResultColumn column) {
    return _dartNames.putIfAbsent(column, () {
      return dartNameForSqlColumn(column.name,
          existingNames: _dartNames.values);
    });
  }

  /// [hashCode] that matches [isCompatibleTo] instead of `==`.
  int get compatibilityHashCode => Object.hash(
        Object.hashAll(columns.map((e) => e.compatibilityHashCode)),
        Object.hashAll(nestedResults.map((e) => e.compatibilityHashCode)),
      );

  /// Checks whether this and the [other] result set have the same columns and
  /// nested result sets.
  bool isCompatibleTo(InferredResultSet other) {
    const columnsEquality = UnorderedIterableEquality(_ResultColumnEquality());
    const nestedEquality = UnorderedIterableEquality(_NestedResultEquality());

    return columnsEquality.equals(columns, other.columns) &&
        nestedEquality.equals(nestedResults, other.nestedResults);
  }
}

/// Information about a matching table. A table matches a query if a query
/// selects all columns from that table, and nothing more.
///
/// We still need to handle column aliases.
class MatchingMoorTable {
  final DriftEntityWithResultSet table;
  final Map<String, DriftColumn> aliasToColumn;

  MatchingMoorTable(this.table, this.aliasToColumn);

  /// Whether the column alias can be ignored.
  ///
  /// This is the case if each result column name maps to a moor column with the
  /// same name.
  bool get effectivelyNoAlias {
    return !aliasToColumn.entries
        .any((entry) => entry.key != entry.value.name.name);
  }
}

class ResultColumn implements HasType {
  final String name;
  @override
  final DriftSqlType type;
  @override
  final bool nullable;

  @override
  final UsedTypeConverter? typeConverter;

  /// The analyzed column from the `sqlparser` package.
  final Column? sqlParserColumn;

  ResultColumn(this.name, this.type, this.nullable,
      {this.typeConverter, this.sqlParserColumn});

  @override
  bool get isArray => false;

  /// Hash-code that matching [compatibleTo], so that two compatible columns
  /// will have the same [compatibilityHashCode].
  int get compatibilityHashCode {
    return Object.hash(name, type, nullable, typeConverter);
  }

  /// Checks whether this column is compatible to the [other], meaning that they
  /// have the same name and type.
  bool compatibleTo(ResultColumn other) {
    return other.name == name &&
        other.type == type &&
        other.nullable == nullable &&
        other.typeConverter == typeConverter;
  }
}

/// A nested result, could either be a NestedResultTable or a NestedQueryResult.
abstract class NestedResult {
  /// [hashCode] that matches [isCompatibleTo] instead of `==`.
  int get compatibilityHashCode;

  /// Checks whether this is compatible to the [other] nested result.
  bool isCompatibleTo(NestedResult other);
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
class NestedResultTable extends NestedResult {
  final bool isNullable;
  final NestedStarResultColumn from;
  final String name;
  final DriftEntityWithResultSet table;

  NestedResultTable(this.from, this.name, this.table, {this.isNullable = true});

  String get dartFieldName => ReCase(name).camelCase;

  /// [hashCode] that matches [isCompatibleTo] instead of `==`.
  @override
  int get compatibilityHashCode {
    return Object.hash(name, table);
  }

  /// Checks whether this is compatible to the [other] nested result, which is
  /// the case iff they have the same and read from the same table.
  @override
  bool isCompatibleTo(NestedResult other) {
    if (other is! NestedResultTable) return false;

    return other.name == name &&
        other.table == table &&
        other.isNullable == isNullable;
  }
}

class NestedResultQuery extends NestedResult {
  final NestedQueryColumn from;

  final SqlSelectQuery query;

  NestedResultQuery({
    required this.from,
    required this.query,
  });

  String filedName() {
    if (from.as != null) {
      return from.as!;
    }

    return ReCase(query.name).camelCase;
  }

  String resultTypeCode() => query.resultTypeCode();

  // Because it is currently not possible to reuse result classes from queries
  // that use nested queries, every instance should be different. Therefore
  // the object hashCode and equality operator is just fine.

  @override
  int get compatibilityHashCode => hashCode;

  @override
  bool isCompatibleTo(NestedResult other) => this == other;
}

/// Something in the query that needs special attention when generating code,
/// such as variables or Dart placeholders.
abstract class FoundElement {
  String get dartParameterName;

  /// The name of this element as declared in the query
  String? get name;

  bool get hasSqlName => name != null;

  /// If the element should be hidden from the parameter list
  bool get hidden => false;

  /// Dart code for a type representing tis element.
  String dartTypeCode();
}

/// A semantic interpretation of a [Variable] in a sql statement.
class FoundVariable extends FoundElement implements HasType {
  /// The (unique) index of this variable in the sql query. For instance, the
  /// query `SELECT * FROM tbl WHERE a = ? AND b = :xyz OR c = :xyz` contains
  /// three [Variable]s in its AST, but only two [FoundVariable]s, where the
  /// `?` will have index 1 and (both) `:xyz` variables will have index 2. We
  /// only report one [FoundVariable] per index.
  int index;

  /// The name of this variable, or null if it's not a named variable.
  @override
  String? name;

  /// The (inferred) type for this variable.
  @override
  final DriftSqlType type;

  /// The type converter to apply before writing this value.
  @override
  final UsedTypeConverter? typeConverter;

  @override
  final bool nullable;

  /// The first [Variable] in the sql statement that has this [index].
  // todo: Do we really need to expose this? We only use [resolvedIndex], which
  // should always be equal to [index].
  final Variable variable;

  /// Whether this variable is an array, which will be expanded into multiple
  /// variables at runtime. We only accept queries where no explicitly numbered
  /// vars appear after an array. This means that we can expand array variables
  /// without having to look at other variables.
  @override
  final bool isArray;

  final bool isRequired;

  @override
  final bool hidden;

  /// When this variable is introduced for a nested query referencing something
  /// from an outer query, contains the backing variable.
  final CapturedVariable? forCaptured;

  FoundVariable({
    required this.index,
    required this.name,
    required this.type,
    required this.variable,
    this.nullable = false,
    this.isArray = false,
    this.isRequired = false,
    this.typeConverter,
  })  : hidden = false,
        forCaptured = null,
        assert(variable.resolvedIndex == index);

  FoundVariable.nestedQuery({
    required this.index,
    required this.name,
    required this.type,
    required this.variable,
    required this.forCaptured,
  })  : typeConverter = null,
        nullable = false,
        isArray = false,
        isRequired = true,
        hidden = true;

  @override
  String get dartParameterName {
    if (name != null) {
      return dartNameForSqlColumn(name!);
    } else {
      return 'var${variable.resolvedIndex}';
    }
  }

  @override
  String dartTypeCode() {
    return OperationOnTypes(this).dartTypeCode();
  }
}

abstract class DartPlaceholderType {
  String parameterTypeCode(
      [GenerationOptions options = const GenerationOptions()]);
}

enum SimpleDartPlaceholderKind {
  limit,
  orderByTerm,
  orderBy,
}

class SimpleDartPlaceholderType extends DartPlaceholderType {
  final SimpleDartPlaceholderKind kind;

  SimpleDartPlaceholderType(this.kind);

  @override
  int get hashCode => kind.hashCode;

  @override
  bool operator ==(Object other) {
    return other is SimpleDartPlaceholderType && other.kind == kind;
  }

  @override
  String parameterTypeCode(
      [GenerationOptions options = const GenerationOptions()]) {
    switch (kind) {
      case SimpleDartPlaceholderKind.limit:
        return 'Limit';
      case SimpleDartPlaceholderKind.orderByTerm:
        return 'OrderingTerm';
      case SimpleDartPlaceholderKind.orderBy:
        return 'OrderBy';
    }
  }
}

class ExpressionDartPlaceholderType extends DartPlaceholderType {
  /// The sql type of this expression.
  final DriftSqlType? columnType;
  final Expression? defaultValue;

  ExpressionDartPlaceholderType(this.columnType, this.defaultValue);

  @override
  int get hashCode => Object.hash(columnType, defaultValue);

  @override
  bool operator ==(Object other) {
    return other is ExpressionDartPlaceholderType &&
        other.columnType == columnType &&
        other.defaultValue == defaultValue;
  }

  @override
  String parameterTypeCode(
      [GenerationOptions options = const GenerationOptions()]) {
    if (columnType == null) return 'Expression';

    final dartType = dartTypeNames[columnType]!;
    return 'Expression<$dartType>';
  }
}

class InsertableDartPlaceholderType extends DartPlaceholderType {
  final DriftTable? table;

  InsertableDartPlaceholderType(this.table);

  @override
  int get hashCode => table.hashCode;

  @override
  bool operator ==(Object other) {
    return other is InsertableDartPlaceholderType && other.table == table;
  }

  @override
  String parameterTypeCode(
      [GenerationOptions options = const GenerationOptions()]) {
    if (table == null) {
      return 'Insertable';
    } else {
      return 'Insertable<${table!.dartTypeCode(options)}>';
    }
  }
}

/// A Dart placeholder that will be bound to a dynamically-generated SQL node
/// at runtime.
///
/// Moor supports injecting expressions, order by terms and clauses and limit
/// clauses as placeholders. For insert statements, companions can be used
/// as a Dart placeholder too.
class FoundDartPlaceholder extends FoundElement {
  final DartPlaceholderType type;

  /// All result sets that are available for this Dart placeholder.
  ///
  /// When queries are operating on multiple tables, especially if some of those
  /// tables have aliases, it may be hard to reflect the name of those tables
  /// at runtime.
  /// For instance, consider this query:
  ///
  /// ```sql
  ///  myQuery: SELECT a.**, b.** FROM users a
  ///    INNER JOIN friends f ON f.a_id = a.id
  ///    INNER JOIN users b ON b.id = f.b_id
  ///  WHERE $expression;
  /// ```
  ///
  /// Here `$expression` is a Dart-defined expression evaluating to an sql
  /// boolean.
  /// Moor uses to add a `Expression<bool>` parameter to the generated query
  /// method. Unfortunately, this puts the burden of picking the right table
  /// name on the user. For instance, they may have to use
  /// `alias('a', users).someColumn` to avoid getting an runtime exception.
  /// With a new build option, moor instead generates a
  /// `Expression<bool> Function(Users a, Users b, Friends f)` function as a
  /// parameter. This allows users to access the right aliases right away,
  /// reducing potential for misuse.
  final List<AvailableMoorResultSet> availableResultSets;

  @override
  final String name;
  DartPlaceholder? astNode;

  bool get hasDefault =>
      type is ExpressionDartPlaceholderType &&
      (type as ExpressionDartPlaceholderType).defaultValue != null;

  bool get hasDefaultOrImplicitFallback =>
      hasDefault ||
      (type is SimpleDartPlaceholderType &&
          (type as SimpleDartPlaceholderType).kind ==
              SimpleDartPlaceholderKind.orderBy);

  FoundDartPlaceholder(this.type, this.name, this.availableResultSets);

  @override
  String get dartParameterName => name;

  @override
  int get hashCode => Object.hashAll([type, name, ...availableResultSets]);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FoundDartPlaceholder &&
            other.type == type &&
            other.name == name &&
            const ListEquality()
                .equals(other.availableResultSets, availableResultSets);
  }

  @override
  String dartTypeCode([GenerationOptions options = const GenerationOptions()]) {
    return type.parameterTypeCode(options);
  }

  /// Whether we should write this parameter as a function having available
  /// result sets as parameters.
  bool writeAsScopedFunction(DriftOptions options) {
    return options.scopedDartComponents &&
        availableResultSets.isNotEmpty &&
        // Don't generate scoped functions for insertables, where the Dart type
        // already defines which fields are available
        type is! InsertableDartPlaceholderType;
  }
}

/// A table or view that is available in the position of a
/// [FoundDartPlaceholder].
///
/// For more information, see [FoundDartPlaceholder.availableResultSets].
class AvailableMoorResultSet {
  /// The (potentially aliased) name of this result set.
  final String name;

  /// The table or view that is available.
  final DriftEntityWithResultSet entity;

  final ResultSetAvailableInStatement? source;

  AvailableMoorResultSet(this.name, this.entity, [this.source]);

  /// The argument type of this result set when used in a scoped function.
  String get argumentType => entity.dslName;

  @override
  int get hashCode => Object.hash(name, entity);

  @override
  bool operator ==(Object other) {
    return other is AvailableMoorResultSet &&
        other.name == name &&
        other.entity == entity;
  }
}

class _ResultColumnEquality implements Equality<ResultColumn> {
  const _ResultColumnEquality();

  @override
  bool equals(ResultColumn e1, ResultColumn e2) => e1.compatibleTo(e2);

  @override
  int hash(ResultColumn e) => e.compatibilityHashCode;

  @override
  bool isValidKey(Object? e) => e is ResultColumn;
}

class _NestedResultEquality implements Equality<NestedResult> {
  const _NestedResultEquality();

  @override
  bool equals(NestedResult e1, NestedResult e2) {
    return e1.isCompatibleTo(e2);
  }

  @override
  int hash(NestedResult e) => e.compatibilityHashCode;

  @override
  bool isValidKey(Object? e) => e is NestedResultTable;
}
