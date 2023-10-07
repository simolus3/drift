import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType, UpdateKind;
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import '../options.dart';
import '../resolver/shared/column_name.dart';
import 'column.dart';
import 'dart.dart';
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
/// translate across serialization runs.
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
  final RequestedQueryResultType? existingDartType;

  final QueryMode mode;

  /// The offset of [sql] in the source file, used to properly report errors
  /// later.
  final int sqlOffset;

  @override
  final List<DriftElement> references;

  @override
  String get name => id.name;

  @override
  String? get dbGetterName {
    if (mode != QueryMode.regular) {
      return DriftSchemaElement.dbFieldName(id.name);
    } else {
      return null;
    }
  }

  @override
  DriftElementKind get kind => DriftElementKind.definedQuery;

  /// All in-line Dart source code literals embedded into the query.
  final List<String> dartTokens;

  /// All Dart type names embedded into the query, for instance in a
  /// `CAST(x AS ENUMNAME(MyDartType))` expression.
  final Map<String, DartType> dartTypes;

  DefinedSqlQuery(
    super.id,
    super.declaration, {
    required this.references,
    required this.sql,
    required this.sqlOffset,
    this.resultClassName,
    this.existingDartType,
    this.dartTokens = const [],
    this.dartTypes = const {},
    this.mode = QueryMode.regular,
  });
}

/// An existing Dart type to be used as the result of a query.
///
/// This is stored in [DefinedSqlQuery.existingDartType] and later validated by
/// [MatchExistingTypeForQuery].
class RequestedQueryResultType {
  final DartType type;
  final String? constructorName;

  RequestedQueryResultType(this.type, this.constructorName);
}

enum QueryMode {
  regular,
  atCreate,
}

///A reference to a [FoundElement] occuring in the SQL query.
class SyntacticElementReference {
  final FoundElement referencedElement;

  SyntacticElementReference(this.referencedElement);
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
  late final List<FoundVariable> variables =
      elements.whereType<FoundVariable>().toList();

  /// The placeholders in this query which are bound and converted to sql at
  /// runtime. For instance, in `SELECT * FROM tbl WHERE $expr`, the `expr` is
  /// going to be a [FoundDartPlaceholder] with the type
  /// [ExpressionDartPlaceholderType] and [DriftSqlType.bool]. We will
  /// generate a method which has a `Expression<bool, BoolType> expr` parameter.
  late final List<FoundDartPlaceholder> placeholders =
      elements.whereType<FoundDartPlaceholder>().toList();

  /// Union of [variables] and [placeholders], but in the order in which they
  /// appear inside the query.
  final List<FoundElement> elements;

  /// All references to any [FoundElement] in [elements], but in the order in
  /// which they appear in the query.
  ///
  /// This is very similar to [elements] itself, except that elements referenced
  /// multiple times are also in this list multiple times. For instance, the
  /// query `SELECT * FROM foo WHERE ?1 ORDER BY $order LIMIT ?1` would have two
  /// elements (the variable and the Dart template, in that order), but three
  /// references (the variable, the template, and then the variable again).
  final List<SyntacticElementReference> elementSources;

  SqlQuery(this.name, this.elements, this.elementSources);

  /// Whether any element in [elements] has more than one definite
  /// [elementSources] pointing to it.
  bool get referencesAnyElementMoreThanOnce {
    final found = <FoundElement>{};
    for (final source in elementSources) {
      if (!found.add(source.referencedElement)) {
        return true;
      }
    }

    return false;
  }

  bool get _useResultClassName {
    final resultSet = this.resultSet!;

    return resultSet.matchingTable == null && !resultSet.singleColumn;
  }

  String get resultClassName {
    final resultSet = this.resultSet;
    if (resultSet == null) {
      throw StateError('This query ($name) does not have a result set');
    }

    if (!_useResultClassName) {
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

  QueryRowType queryRowType(DriftOptions options) {
    final resultSet = this.resultSet;
    if (resultSet == null) {
      throw StateError('This query ($name) does not have a result set');
    }

    return resultSet.mappingToRowClass(
        _useResultClassName ? resultClassName : null, options);
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

  SqlSelectQuery(
    String name,
    this.fromContext,
    this.root,
    List<FoundElement> elements,
    List<SyntacticElementReference> elementSources,
    this.readsFrom,
    this.resultSet,
    this.requestedResultClass,
    this.nestedContainer,
  ) : super(name, elements, elementSources);

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
      elementSources,
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

  /// The nested queries transformation may change the index of variables used
  /// in a query.
  ///
  /// For instance, in `SELECT a, LIST(SELECT b FROM foo WHERE :a) FROM foo
  /// WHERE :b = 2`, the variable `:a` is initially given the index 1, while
  /// `:b` gets the index `2`.
  /// After the transformation though, we end up with two queries `SELECT a
  /// FROM foo WHERE :b = 2` (in which `:b` now has the index `1`), and
  /// `SELECT b FROM foo WHERE :a`. The [Variable.resolvedIndex] will report
  /// the correct index after the nested queries transformation, but for looking
  /// up types it is beneficial to learn about the original index, since
  /// variables with different indexes are considered different variables.
  final Map<Variable, int> originalIndexForVariable = {};

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
    List<SyntacticElementReference> elementSources,
    this.updates, {
    this.isInsert = false,
    this.resultSet,
  }) : super(name, elements, elementSources);
}

/// A special kind of query running multiple inner queries in a transaction.
class InTransactionQuery extends SqlQuery {
  final List<SqlQuery> innerQueries;

  InTransactionQuery(this.innerQueries, String name)
      : super(
          name,
          [for (final query in innerQueries) ...query.elements],
          [for (final query in innerQueries) ...query.elementSources],
        );

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

  Map<NestedResult, String>? _expandedNestedPrefixes;

  /// All columns that are part of this result set.
  ///
  /// This includes [ScalarResultColumn]s, which hold simple SQL values, but
  /// also [NestedResult]s, which hold subqueries or tables that are structured
  /// into a single logical Dart column.
  final List<ResultColumn> columns;
  final Map<ResultColumn, String> _dartNames = {};

  /// The name of the Dart class generated to store this result set, or null if
  /// it hasn't explicitly been set.
  final String? resultClassName;

  /// If specified, an existing user-defined Dart type to use instead of
  /// generating another class for the result of this query.
  final QueryRowType? existingRowType;

  /// Explicitly controls that no result class should be generated for this
  /// result set.
  ///
  /// This is enabled on duplicate result sets caused by custom result class
  /// names.
  final bool dontGenerateResultClass;

  InferredResultSet(
    this.matchingTable,
    this.columns, {
    this.resultClassName,
    this.existingRowType,
    this.dontGenerateResultClass = false,
  });

  Iterable<ScalarResultColumn> get scalarColumns => columns.whereType();
  Iterable<NestedResult> get nestedResults => columns.whereType();

  /// Whether a new class needs to be written to store the result of this query.
  ///
  /// We don't need to introduce result classes for queries which
  /// - return an existing table model
  /// - return exactly one column
  ///
  /// We always need to generate a class if the query contains nested results.
  bool get needsOwnClass {
    return matchingTable == null &&
        existingRowType == null &&
        (scalarColumns.length > 1 || nestedResults.isNotEmpty) &&
        !dontGenerateResultClass;
  }

  /// Whether this query returns a single column that should be returned
  /// directly.
  bool get singleColumn =>
      matchingTable == null &&
      nestedResults.isEmpty &&
      scalarColumns.length == 1;

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
      return column.dartGetterName(_dartNames.values);
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
    return columnsEquality.equals(columns, other.columns);
  }

  /// Returns [existingRowType], or constructs an equivalent mapping to the
  /// default row class generated by drift_dev.
  ///
  /// The code to map raw result sets into structured data, be it into a class
  /// written by a user or something generated by drift_dev, is really similar.
  /// To share that logic in the query writer, we represent both mappings with
  /// the same [QueryRowType] class.
  QueryRowType mappingToRowClass(
      String? resultClassName, DriftOptions options) {
    final existingType = existingRowType;
    final matchingTable = this.matchingTable;

    if (existingType != null) {
      return existingType;
    } else if (singleColumn) {
      final column = scalarColumns.single;

      return QueryRowType(
        rowType: AnnotatedDartCode.build((b) => b.addDriftType(column)),
        singleValue: _columnAsArgument(column, options),
        positionalArguments: const [],
        namedArguments: const {},
      );
    } else if (matchingTable != null) {
      return QueryRowType(
        rowType: AnnotatedDartCode.build(
            (b) => b.addElementRowType(matchingTable.table)),
        singleValue: matchingTable,
        positionalArguments: const [],
        namedArguments: const {},
      );
    } else {
      return QueryRowType(
        rowType: AnnotatedDartCode.build((b) => b.addText(resultClassName!)),
        singleValue: null,
        positionalArguments: const [],
        namedArguments: {
          if (options.rawResultSetData) 'row': RawQueryRow(),
          for (final column in columns)
            dartNameFor(column): _columnAsArgument(column, options),
        },
      );
    }
  }

  ArgumentForQueryRowType _columnAsArgument(
    ResultColumn column,
    DriftOptions options,
  ) {
    return switch (column) {
      ScalarResultColumn() => column,
      NestedResultTable() => StructuredFromNestedColumn(
          column,
          column.innerResultSet
              .mappingToRowClass(column.nameForGeneratedRowClass, options),
        ),
      NestedResultQuery() => MappedNestedListQuery(
          column,
          column.query.queryRowType(options),
        ),
    };
  }
}

/// Describes a data type for a query, and how to map raw data into that
/// structured type.
class QueryRowType implements ArgumentForQueryRowType {
  final AnnotatedDartCode rowType;
  final String constructorName;
  final bool isRecord;

  /// When set, instead of constructing the [rowType] from the arguments, the
  /// argument specified here can just be cast into the desired [rowType].
  ArgumentForQueryRowType? singleValue;

  final List<ArgumentForQueryRowType> positionalArguments;
  final Map<String, ArgumentForQueryRowType> namedArguments;

  QueryRowType({
    required this.rowType,
    required this.singleValue,
    required this.positionalArguments,
    required this.namedArguments,
    this.constructorName = '',
    this.isRecord = false,
  });

  Iterable<ArgumentForQueryRowType> get allArguments sync* {
    if (singleValue != null) {
      yield singleValue!;
    } else {
      yield* positionalArguments;
      yield* namedArguments.values;
    }
  }

  @override
  bool get requiresAsynchronousContext =>
      allArguments.any((arg) => arg.requiresAsynchronousContext);

  @override
  String toString() {
    return 'ExistingQueryRowType(type: $rowType, singleValue: $singleValue, '
        'positional: $positionalArguments, named: $namedArguments)';
  }
}

sealed class ArgumentForQueryRowType {
  /// Whether the code constructing this argument may need to be in an async
  /// context.
  bool get requiresAsynchronousContext;
}

/// An argument that just maps the raw query row.
///
/// This is used for generated query classes which can optionally hold a
/// reference to the raw result set.
class RawQueryRow extends ArgumentForQueryRowType {
  @override
  bool get requiresAsynchronousContext => false;
}

class StructuredFromNestedColumn extends ArgumentForQueryRowType {
  final NestedResultTable table;
  final QueryRowType nestedType;

  bool get nullable => table.isNullable;

  StructuredFromNestedColumn(this.table, this.nestedType);

  @override
  bool get requiresAsynchronousContext =>
      nestedType.requiresAsynchronousContext;
}

class MappedNestedListQuery extends ArgumentForQueryRowType {
  final NestedResultQuery column;
  final QueryRowType nestedType;

  MappedNestedListQuery(this.column, this.nestedType);

  // List queries run another statement and always need an asynchronous mapping.
  @override
  bool get requiresAsynchronousContext => true;
}

/// Information about a matching table. A table matches a query if a query
/// selects all columns from that table, and nothing more.
///
/// We still need to handle column aliases.
class MatchingDriftTable implements ArgumentForQueryRowType {
  final DriftElementWithResultSet table;
  final Map<String, DriftColumn> aliasToColumn;

  MatchingDriftTable(this.table, this.aliasToColumn);

  @override
  // Mapping from tables is currently asynchronous because the existing data
  // class could be an asynchronous factory.
  bool get requiresAsynchronousContext => true;

  /// Whether the column alias can be ignored.
  ///
  /// This is the case if each result column name maps to a drift column with
  /// the same SQL name.
  bool get effectivelyNoAlias {
    return !aliasToColumn.entries
        .any((entry) => entry.key != entry.value.nameInSql);
  }
}

sealed class ResultColumn {
  /// A unique name for this column in Dart.
  String dartGetterName(Iterable<String> existingNames);

  /// [hashCode] that matches [isCompatibleTo] instead of `==`.
  int get compatibilityHashCode;

  /// Checks whether this column is compatible to the [other] column, meaning
  /// that they have the same name and type.
  bool isCompatibleTo(ResultColumn other);
}

final class ScalarResultColumn extends ResultColumn
    implements HasType, ArgumentForQueryRowType {
  final String name;
  @override
  final ColumnType sqlType;
  @override
  final bool nullable;

  @override
  final AppliedTypeConverter? typeConverter;

  /// The analyzed column from the `sqlparser` package.
  final Column? sqlParserColumn;

  ScalarResultColumn(this.name, this.sqlType, this.nullable,
      {this.typeConverter, this.sqlParserColumn});

  @override
  bool get isArray => false;

  @override
  bool get requiresAsynchronousContext => false;

  @override
  String dartGetterName(Iterable<String> existingNames) {
    return dartNameForSqlColumn(name, existingNames: existingNames);
  }

  int get _columnTypeCompatibilityHash {
    return Object.hash(sqlType.builtin, sqlType.custom?.dartType);
  }

  @override
  int get compatibilityHashCode {
    return Object.hash(ScalarResultColumn, name, _columnTypeCompatibilityHash,
        nullable, typeConverter);
  }

  @override
  bool isCompatibleTo(ResultColumn other) {
    return other is ScalarResultColumn &&
        other.name == name &&
        other.sqlType.builtin == sqlType.builtin &&
        other.sqlType.custom?.dartType == sqlType.custom?.dartType &&
        other.nullable == nullable &&
        other.typeConverter == typeConverter;
  }
}

/// A nested result, could either be a [NestedResultTable] or a
/// [NestedResultQuery].
sealed class NestedResult extends ResultColumn {}

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
final class NestedResultTable extends NestedResult {
  final bool isNullable;
  final NestedStarResultColumn from;
  final String name;

  /// The inner result set, e.g. the table or subquery/table-valued function
  /// that the [from] column resolves to.
  final InferredResultSet innerResultSet;

  final String nameForGeneratedRowClass;

  NestedResultTable({
    required this.from,
    required this.name,
    required this.innerResultSet,
    required this.nameForGeneratedRowClass,
    this.isNullable = true,
  });

  @override
  String dartGetterName(Iterable<String> existingNames) {
    return dartNameForSqlColumn(name, existingNames: existingNames);
  }

  /// [hashCode] that matches [isCompatibleTo] instead of `==`.
  @override
  int get compatibilityHashCode {
    return Object.hash(name, innerResultSet.compatibilityHashCode);
  }

  /// Checks whether this is compatible to the [other] nested result, which is
  /// the case iff they have the same and read from the same table.
  @override
  bool isCompatibleTo(ResultColumn other) {
    if (other is! NestedResultTable) return false;

    return other.name == name &&
        other.innerResultSet.isCompatibleTo(other.innerResultSet) &&
        other.isNullable == isNullable;
  }
}

final class NestedResultQuery extends NestedResult {
  final NestedQueryColumn from;

  final SqlSelectQuery query;

  NestedResultQuery({
    required this.from,
    required this.query,
  });

  @override
  String dartGetterName(Iterable<String> existingNames) {
    return dartNameForSqlColumn(filedName(), existingNames: existingNames);
  }

  String filedName() {
    if (from.as != null) {
      return from.as!;
    }

    return ReCase(query.name).camelCase;
  }

  @override
  int get compatibilityHashCode =>
      Object.hash(NestedResultQuery, query.resultSet.compatibilityHashCode);

  @override
  bool isCompatibleTo(ResultColumn other) {
    return other is NestedResultQuery &&
        query.resultSet.isCompatibleTo(other.query.resultSet);
  }
}

/// Something in the query that needs special attention when generating code,
/// such as variables or Dart placeholders.
sealed class FoundElement {
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
  ///
  /// This [index] might change in the generator as variables are moved around.
  /// See [originalIndex] for the original index and a further discussion of
  /// this.
  int index;

  /// The original index this variable had in the SQL string written by the
  /// user.
  ///
  /// In the generator, we might have to shuffle variable indices around a bit
  /// to support array variables which occupy a dynamic amount of variable
  /// indices at runtime.
  /// For instance, consider `SELECT * FROM foo WHERE a = :a OR b IN :b OR c = :c`.
  /// Here, `:c` will have an original index of 3. Since `:b` is an array
  /// variable though, the actual query sent to the database system at runtime
  /// will look like `SELECT * FROM foo WHERE a = ?1 OR b IN (?3, ?4) OR c = ?2`
  /// when a size-2 list is passed for `b`. All non-array variables have been
  /// given indices that appear before the array to support this, so the [index]
  /// of `c` would then be `2`.
  final int originalIndex;

  /// The name of this variable, or null if it's not a named variable.
  @override
  String? name;

  /// The (inferred) type for this variable.
  @override
  final ColumnType sqlType;

  /// The type converter to apply before writing this value.
  @override
  final AppliedTypeConverter? typeConverter;

  @override
  final bool nullable;

  @override
  final AstNode syntacticOrigin;

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
    required Variable variable,
    this.nullable = false,
    this.isArray = false,
    this.isRequired = false,
    this.typeConverter,
  })  : originalIndex = index,
        hidden = false,
        syntacticOrigin = variable,
        forCaptured = null;

  FoundVariable.nestedQuery({
    required this.index,
    required this.name,
    required this.sqlType,
    required Variable variable,
    required this.forCaptured,
  })  : originalIndex = index,
        typeConverter = null,
        nullable = false,
        isArray = false,
        isRequired = true,
        hidden = true,
        syntacticOrigin = variable;

  @override
  String get dartParameterName {
    if (name != null) {
      return dartNameForSqlColumn(name!);
    } else {
      return 'var$index';
    }
  }
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
  final ColumnType? columnType;
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
  bool equals(ResultColumn e1, ResultColumn e2) => e1.isCompatibleTo(e2);

  @override
  int hash(ResultColumn e) => e.compatibilityHashCode;

  @override
  bool isValidKey(Object? e) => e is ResultColumn;
}
