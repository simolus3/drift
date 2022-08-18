part of '../analysis.dart';

/// Mixin for classes which represent a reference.
mixin ReferenceOwner {
  /// The resolved reference, or null if it hasn't been resolved yet.
  Referencable? resolved;
}

/// Mixin for classes which can be referenced by a [ReferenceOwner].
mixin Referencable {
  /// Whether this referencable is still visible in child scopes. This doesn't
  /// apply to many things, basically only to tables.
  ///
  /// For instance: "SELECT *, 1 AS d, (SELECT id FROM demo WHERE id = out.id)
  /// FROM demo AS out;"
  /// is a valid sql query when the demo table has an id column. However,
  /// "SELECT *, 1 AS d, (SELECT id FROM demo WHERE id = d) FROM demo AS out;"
  /// is not, the "d" referencable is not visible for the child select
  /// statement.
  bool get visibleToChildren => false;
}

/// A class managing which tables and columns are visible to which AST nodes.
abstract class ReferenceScope {
  RootScope get rootScope;

  /// The list of column to which a `*` would expand to.
  ///
  /// This is not necessary the same list of columns that could be resolved
  /// through [resolveUnqualifiedReference]. For subquery expressions, columns
  /// in parent scopes may be referenced without a qualified, but they don't
  /// appear in a `*` expansion for the subquery.
  List<Column>? get expansionOfStarColumn => null;

  /// Attempts to find a result set that has been added to this scope, for
  /// instance because it was introduced in a `FROM` clause.
  ///
  /// This is useful to resolve qualified references (e.g. to resolve `foo.bar`
  /// the resolver would call [resolveResultSet]("foo") and then look up the
  /// `bar` column in that result set).
  ResultSetAvailableInStatement? resolveResultSet(String name) => null;

  /// Adds an added result set to this scope.
  ///
  /// This operation is not supported for all kinds of scopes, a [StateError]
  /// is thrown for invalid scopes.
  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    throw StateError('Result set cannot be added in this scope: $this');
  }

  /// Registers a [ResultSetAvailableInStatement] to a [TableAlias] for the
  /// given [resultSet].
  ///
  /// Like [addResolvedResultSet], this operation is not supported on all
  /// scopes.
  void addAlias(AstNode origin, ResultSet resultSet, String alias) {
    final createdAlias = TableAlias(resultSet, alias);
    addResolvedResultSet(
        alias, ResultSetAvailableInStatement(origin, createdAlias));
  }

  /// Attempts to find a result set that _can_ be added to a scope.
  ///
  /// This is used to resolve table references. Usually, after a result set to
  /// add has been resolve,d a [ResultSetAvailableInStatement] is added to the
  /// scope and [resolveResultSet] will find that afterwards.
  ResultSet? resolveResultSetToAdd(String name) => rootScope.knownTables[name];

  /// Attempts to resolve an unqualified reference from a [columnName].
  ///
  /// In sqlite, an `ORDER BY` column may refer to aliases of result columns
  /// in the current statement: `SELECT foo AS bar FROM tbl ORDER BY bar` is
  /// legal, but `SELECT foo AS bar FROM tbl WHERE bar < 10` is not. To control
  /// whether result columns may be resolved, the [allowReferenceToResultColumn]
  /// flag can be enabled.
  ///
  /// If an empty list is returned, the reference couldn't be resolved. If the
  /// returned list contains more than one column, the lookup is ambigious.
  List<Column> resolveUnqualifiedReference(String columnName,
          {bool allowReferenceToResultColumn = false}) =>
      const [];
}

/// The root scope created by the SQL engine to analyze a statement.
///
/// This contains known tables (or views) and modules to look up.
class RootScope extends ReferenceScope {
  @override
  RootScope get rootScope => this;

  /// All tables (or views, or other result sets) that are known in the current
  /// schema.
  ///
  /// [resolveResultSetToAdd] will query these tables by default.
  final Map<String, ResultSet> knownTables = CaseInsensitiveMap();

  /// Known modules that are registered for this statement.
  ///
  /// This is used to resolve `CREATE VIRTUAL TABLE` statements.
  final Map<String, Module> knownModules = CaseInsensitiveMap();
}

/// A scope used by statements.
///
/// Tables added from `FROM` clauses are added to [resultSets], CTEs are added
/// to [additionalKnownTables].
///
/// This is the scope most commonly used, but specific nodes may be attached to
/// a different scope in case they have limited visibility. For instance,
///  - foreign key clauses are wrapped in a [SingleTableReferenceScope] because
///    they can't see unqualified columns of the overal scope.
///  - subquery expressions can see parent tables and columns, but their columns
///    aren't visible in the parent statement. This is implemented by wrapping
///    them in a [StatementScope] as well.
///  - subqueries appearing in a `FROM` clause _can't_ see outer columns and
///    tables. These statements are also wrapped in a [StatementScope], but a
///    [SubqueryInFromScope] is insertted as an intermediatet scope to prevent
///    the inner scope from seeing the outer columns.

class StatementScope extends ReferenceScope {
  final ReferenceScope parent;

  /// Additional tables (that haven't necessarily been added in a `FROM` clause
  /// that are only visible in this scope).
  ///
  /// This is commonly used for common table expressions, e.g a `WITH foo AS
  /// (...)` would add a result set `foo` into the [additionalKnownTables] of
  /// the overall statement, because `foo` can now be selected.
  final Map<String, ResultSet> additionalKnownTables = CaseInsensitiveMap();

  /// Result sets that were added through a `FROM` clause and are now available
  /// in this scope.
  ///
  /// The [ResultSetAvailableInStatement] contains information about the AST
  /// node causing this statement to be available.
  final Map<String?, ResultSetAvailableInStatement> resultSets =
      CaseInsensitiveMap();

  /// For select statements, additional columns available under a name because
  /// there were added after the `SELECT`.
  ///
  /// This is used to resolve unqualified references by `ORDER BY` clauses.
  final List<Column> namedResultColumns = [];

  final Map<String, NamedWindowDeclaration> windowDeclarations =
      CaseInsensitiveMap();

  /// All columns that a (unqualified) `*` in a select statement or function
  /// call argument would expand to.
  @override
  List<Column>? expansionOfStarColumn;

  StatementScope(this.parent);

  StatementScope? get parentStatementScope {
    final parent = this.parent;
    if (parent is StatementScope) {
      return parent;
    } else if (parent is MiscStatementSubScope) {
      return parent.parent;
    } else {
      return null;
    }
  }

  /// All result sets available in this and parent scopes.
  Iterable<ResultSetAvailableInStatement> get allAvailableResultSets {
    final here = resultSets.values;
    final parent = parentStatementScope;
    return parent != null
        ? here.followedBy(parent.allAvailableResultSets)
        : here;
  }

  @override
  RootScope get rootScope => parent.rootScope;

  @override
  void addAlias(AstNode origin, ResultSet resultSet, String alias) {
    final createdAlias = TableAlias(resultSet, alias);
    additionalKnownTables[alias] = createdAlias;
    resultSets[alias] = ResultSetAvailableInStatement(origin, createdAlias);
  }

  @override
  ResultSetAvailableInStatement? resolveResultSet(String name) {
    return resultSets[name] ?? parentStatementScope?.resolveResultSet(name);
  }

  @override
  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    resultSets[name] = resultSet;
  }

  @override
  ResultSet? resolveResultSetToAdd(String name) {
    return additionalKnownTables[name] ??
        parentStatementScope?.resolveResultSetToAdd(name) ??
        rootScope.knownTables[name];
  }

  @override
  List<Column> resolveUnqualifiedReference(String columnName,
      {bool allowReferenceToResultColumn = false}) {
    if (allowReferenceToResultColumn) {
      final foundColumn = namedResultColumns.firstWhereOrNull(
          (c) => c.name.toLowerCase() == columnName.toLowerCase());
      if (foundColumn != null) {
        return [foundColumn];
      }
    }

    StatementScope? currentScope = this;

    // Search scopes for a matching column in an added result set. If a column
    // reference is found in a closer scope, it takes precedence over outer
    // scopes. However, it's an error if two columns with the same name are
    // found in the same scope.
    while (currentScope != null) {
      final available = currentScope.resultSets.values;
      final sourceColumns = <Column>{};
      final availableColumns = <AvailableColumn>[];

      for (final availableSource in available) {
        final resolvedColumns =
            availableSource.resultSet.resultSet?.resolvedColumns;
        if (resolvedColumns == null) continue;

        for (final column in resolvedColumns) {
          if (column.name.toLowerCase() == columnName.toLowerCase() &&
              sourceColumns.add(column)) {
            availableColumns.add(AvailableColumn(column, availableSource));
          }
        }
      }

      if (availableColumns.isEmpty) {
        currentScope = currentScope.parentStatementScope;
        if (currentScope == null) {
          // Reached the outermost scope without finding a reference target.
          return const [];
        }
        continue;
      } else {
        return availableColumns;
      }
    }

    return const [];
  }

  factory StatementScope.forStatement(RootScope root, Statement statement) {
    return StatementScope(statement.optionalScope ?? root);
  }

  static StatementScope cast(ReferenceScope other) {
    if (other is StatementScope) {
      return other;
    } else if (other is MiscStatementSubScope) {
      return other.parent;
    } else {
      throw ArgumentError.value(
          other, 'other', 'Not resolvable to a statement scope');
    }
  }
}

/// A special intermediate scope used for subqueries appearing in a `FROM`
/// clause so that the subquery can't see outer columns and tables being added.
class SubqueryInFromScope extends ReferenceScope {
  final StatementScope enclosingStatement;

  SubqueryInFromScope(this.enclosingStatement);

  @override
  RootScope get rootScope => enclosingStatement.rootScope;
}

/// A rarely used sub-scope for AST nodes that belong to a statement, but may
/// have access to more result sets.
///
/// For instance, the body of an `ON CONFLICT DO UPDATE`-clause may refer to a
/// table alias `excluded` to get access to a conflicting table.
class MiscStatementSubScope extends ReferenceScope {
  final StatementScope parent;

  final Map<String?, ResultSetAvailableInStatement> additionalResultSets =
      CaseInsensitiveMap();

  MiscStatementSubScope(this.parent);

  @override
  RootScope get rootScope => parent.rootScope;

  @override
  ResultSetAvailableInStatement? resolveResultSet(String name) {
    return additionalResultSets[name] ?? parent.resolveResultSet(name);
  }

  @override
  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    additionalResultSets[name] = resultSet;
  }

  @override
  List<Column> resolveUnqualifiedReference(String columnName,
      {bool allowReferenceToResultColumn = false}) {
    return parent.resolveUnqualifiedReference(columnName);
  }
}

/// A reference scope that only allows a single added result set.
///
/// This is used for e.g. foreign key clauses (`REFERENCES table (a, b, c)`),
/// where `a`, `b` and `c` can only refer to `table`.
class SingleTableReferenceScope extends ReferenceScope {
  final ReferenceScope parent;

  String? addedTableName;
  ResultSetAvailableInStatement? addedTable;

  SingleTableReferenceScope(this.parent);

  @override
  RootScope get rootScope => parent.rootScope;

  @override
  ResultSetAvailableInStatement? resolveResultSet(String name) {
    if (name == addedTableName) {
      return addedTable;
    } else {
      return null;
    }
  }

  @override
  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    addedTableName = null;
    addedTable = null;
  }

  @override
  List<Column> resolveUnqualifiedReference(String columnName,
      {bool allowReferenceToResultColumn = false}) {
    final column = addedTable?.resultSet.resultSet?.findColumn(columnName);
    if (column != null) {
      return [AvailableColumn(column, addedTable!)];
    } else {
      return const [];
    }
  }
}
