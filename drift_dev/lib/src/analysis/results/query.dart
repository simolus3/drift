import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType, UpdateKind;
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import '../options.dart';
import '../resolver/shared/column_name.dart';
import 'column.dart';
import 'element.dart';
import 'result_sets.dart';
import 'table.dart';
import 'types.dart';
import 'view.dart';

abstract class DriftQueryDeclaration {
  String get name;
}

/// A named SQL query defined in a `.drift` file. A later compile step will
/// further analyze this query and run analysis on it.
///
/// We deliberately only store very basic information here: The actual query
/// model is very complex and hard to serialize. Further, lots of generation
/// logic requires actual references to the AST which will be difficult to
/// translate across serialization run.
/// Since SQL queries only need to be fully analyzed before generation, and
/// since they are local elements which can't be referenced by others, there's
/// no clear advantage wrt. incremental compilation if queries are fully
/// analyzed and serialized. So, we just do this in the generator.
class DefinedSqlQuery extends DriftElement implements DriftQueryDeclaration {
  /// The unmodified source of the declared SQL statement forming this query.
  final String sql;

  /// The overriden name of a result class that drift should generate for this
  /// query.
  ///
  /// When multiple queries share the same result class name, drift will verify
  /// that this is possible and map all these queries into the same generated
  /// class.
  final String? resultClassName;

  /// The existing Dart type into which a result row of this query should be
  /// mapped.
  final DartType? existingDartType;

  final QueryMode mode;

  /// The offset of [sql] in the source file, used to properly report errors
  /// later.
  final int sqlOffset;

  @override
  final List<DriftElement> references;

  @override
  String get name => id.name;

  DefinedSqlQuery(
    super.id,
    super.declaration, {
    required this.references,
    required this.sql,
    required this.sqlOffset,
    this.resultClassName,
    this.existingDartType,
    this.mode = QueryMode.regular,
  });
}

enum QueryMode {
  regular,
  atCreate,
}

/// A fully-resolved and analyzed SQL query.
abstract class SqlQuery {
  final String name;

  AnalysisContext? get fromContext;
  AstNode? get root;

  /// Whether this query was declared in a `.drift` file.
  ///
  /// At the moment, there is not much of a difference between drift-defined
  /// queries and those defined on a database annotation.
  /// However, with a legacy build option, additional `get` and `watch` method
  /// are generated for Dart queries whereas drift-defined queries will only
  /// generate a single method returning a `Selectable`.
  bool declaredInDriftFile = false;

  String? get sql => fromContext?.sql;

  /// The result set of this statement, mapped to drift-generated classes.
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
  final List<DriftElement> readsFrom;
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
        else if (entity is DriftView)
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

class WrittenDriftTable {
  final DriftTable table;
  final UpdateKind kind;

  WrittenDriftTable(this.table, this.kind);
}

class UpdatingQuery extends SqlQuery {
  final List<WrittenDriftTable> updates;
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
  final MatchingDriftTable? matchingTable;

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
class MatchingDriftTable {
  final DriftElementWithResultSet table;
  final Map<String, DriftColumn> aliasToColumn;

  MatchingDriftTable(this.table, this.aliasToColumn);

  /// Whether the column alias can be ignored.
  ///
  /// This is the case if each result column name maps to a drift column with
  /// the same SQL name.
  bool get effectivelyNoAlias {
    return !aliasToColumn.entries
        .any((entry) => entry.key != entry.value.nameInSql);
  }
}

class ResultColumn implements HasType {
  final String name;
  @override
  final DriftSqlType sqlType;
  @override
  final bool nullable;

  @override
  final AppliedTypeConverter? typeConverter;

  /// The analyzed column from the `sqlparser` package.
  final Column? sqlParserColumn;

  ResultColumn(this.name, this.sqlType, this.nullable,
      {this.typeConverter, this.sqlParserColumn});

  @override
  bool get isArray => false;

  /// Hash-code that matching [compatibleTo], so that two compatible columns
  /// will have the same [compatibilityHashCode].
  int get compatibilityHashCode {
    return Object.hash(name, sqlType, nullable, typeConverter);
  }

  /// Checks whether this column is compatible to the [other], meaning that they
  /// have the same name and type.
  bool compatibleTo(ResultColumn other) {
    return other.name == name &&
        other.sqlType == sqlType &&
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
  final DriftElementWithResultSet table;

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

  /// Returns a syntactic origin for this element in the query.
  ///
  /// Some elements may have more than one origin. For instance, the query
  /// `SELECT ?, ?1` only contains one logical [FoundVariable], but two
  /// syntactic origins. This getter will return one of them, but the exact
  /// source is undefined in that case.
  AstNode get syntacticOrigin;
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
  final DriftSqlType sqlType;

  /// The type converter to apply before writing this value.
  @override
  final AppliedTypeConverter? typeConverter;

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
    required this.sqlType,
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
    required this.sqlType,
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
  AstNode get syntacticOrigin => variable;
}

abstract class DartPlaceholderType {}

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
}

/// A Dart placeholder that will be bound to a dynamically-generated SQL node
/// at runtime.
///
/// Drift supports injecting expressions, order by terms and clauses and limit
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
  /// Drift uses to add a `Expression<bool>` parameter to the generated query
  /// method. Unfortunately, this puts the burden of picking the right table
  /// name on the user. For instance, they may have to use
  /// `alias('a', users).someColumn` to avoid getting an runtime exception.
  /// With a new build option, drift instead generates a
  /// `Expression<bool> Function(Users a, Users b, Friends f)` function as a
  /// parameter. This allows users to access the right aliases right away,
  /// reducing potential for misuse.
  final List<AvailableDriftResultSet> availableResultSets;

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

  /// Whether we should write this parameter as a function having available
  /// result sets as parameters.
  bool writeAsScopedFunction(DriftOptions options) {
    return options.scopedDartComponents &&
        availableResultSets.isNotEmpty &&
        // Don't generate scoped functions for insertables, where the Dart type
        // already defines which fields are available
        type is! InsertableDartPlaceholderType;
  }

  @override
  AstNode get syntacticOrigin => astNode!;
}

/// A table or view that is available in the position of a
/// [FoundDartPlaceholder].
///
/// For more information, see [FoundDartPlaceholder.availableResultSets].
class AvailableDriftResultSet {
  /// The (potentially aliased) name of this result set.
  final String name;

  /// The table or view that is available.
  final DriftElementWithResultSet entity;

  final ResultSetAvailableInStatement? source;

  AvailableDriftResultSet(this.name, this.entity, [this.source]);

  @override
  int get hashCode => Object.hash(name, entity);

  @override
  bool operator ==(Object other) {
    return other is AvailableDriftResultSet &&
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
