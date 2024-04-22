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

  /// All available result sets that can also be seen in child scopes.
  ///
  /// Usually, this is the same list as the result sets being declared in this
  /// scope. However, some exceptions apply (see e.g. [SourceScope]).
  Iterable<ResultSetAvailableInStatement> get resultSetAvailableToChildScopes =>
      const Iterable.empty();

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
  ResultSetAvailableInStatement? resolveResultSetForReference(String name) =>
      null;

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
  ///
  /// [canUseUnqualifiedColumns] controls whether [resolveUnqualifiedReference]
  /// considers the alias when resolving references. Some aliases, such as `new`
  /// and `old` in triggers, can only be used in their qualified form and thus
  /// have that parameter set to false.
  void addAlias(
    AstNode origin,
    ResultSet resultSet,
    String alias, {
    bool canUseUnqualifiedColumns = true,
  }) {
    final createdAlias = TableAlias(resultSet, alias);
    addResolvedResultSet(
      alias,
      ResultSetAvailableInStatement(origin, createdAlias,
          canUseUnqualifiedColumns: canUseUnqualifiedColumns),
    );
  }

  /// Attempts to find a result set that _can_ be added to a scope.
  ///
  /// This is used to resolve table references. Usually, after a result set to
  /// add has been resolve,d a [ResultSetAvailableInStatement] is added to the
  /// scope and [resolveResultSet] will find that afterwards.
  ResultSet? resolveResultSetToAdd(String name) {
    return rootScope.resolveResultSetToAdd(name);
  }

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

  @override
  ResultSet? resolveResultSetToAdd(String name) {
    return knownTables[name];
  }
}

mixin _HasParentScope on ReferenceScope {
  ReferenceScope get _parentScopeForLookups;

  @override
  RootScope get rootScope => _parentScopeForLookups.rootScope;

  @override
  Iterable<ResultSetAvailableInStatement> get resultSetAvailableToChildScopes =>
      _parentScopeForLookups.resultSetAvailableToChildScopes;

  @override
  ResultSetAvailableInStatement? resolveResultSetForReference(String name) =>
      _parentScopeForLookups.resolveResultSetForReference(name);

  @override
  ResultSet? resolveResultSetToAdd(String name) =>
      _parentScopeForLookups.resolveResultSetToAdd(name);

  @override
  List<Column> resolveUnqualifiedReference(String columnName,
          {bool allowReferenceToResultColumn = false}) =>
      _parentScopeForLookups.resolveUnqualifiedReference(columnName);
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
///    [SourceScope] is inserted as an intermediate scope to prevent the inner
///    scope from seeing the outer columns.

class StatementScope extends ReferenceScope with _HasParentScope {
  final ReferenceScope parent;

  @override
  get _parentScopeForLookups => parent;

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

  @override
  Iterable<ResultSetAvailableInStatement> get resultSetAvailableToChildScopes {
    return allAvailableResultSets;
  }

  /// All result sets available in this and parent scopes.
  Iterable<ResultSetAvailableInStatement> get allAvailableResultSets {
    final here = resultSets.values;
    return parent.resultSetAvailableToChildScopes.followedBy(here);
  }

  @override
  void addAlias(
    AstNode origin,
    ResultSet resultSet,
    String alias, {
    bool canUseUnqualifiedColumns = true,
  }) {
    final createdAlias = TableAlias(resultSet, alias);
    resultSets[alias] = ResultSetAvailableInStatement(origin, createdAlias,
        canUseUnqualifiedColumns: canUseUnqualifiedColumns);
  }

  @override
  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    resultSets[name] = resultSet;
  }

  @override
  ResultSetAvailableInStatement? resolveResultSetForReference(String name) {
    return resultSets[name] ?? parent.resolveResultSetForReference(name);
  }

  @override
  ResultSet? resolveResultSetToAdd(String name) {
    return additionalKnownTables[name] ?? parent.resolveResultSetToAdd(name);
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

    final available = resultSets.values;
    final sourceColumns = <Column>{};
    final availableColumns = <AvailableColumn>[];

    for (final availableSource in available) {
      final resolvedColumns =
          availableSource.resultSet.resultSet?.resolvedColumns;
      if (resolvedColumns == null ||
          !availableSource.canUseUnqualifiedColumns) {
        continue;
      }

      for (final column in resolvedColumns) {
        if (column.name.toLowerCase() == columnName.toLowerCase() &&
            sourceColumns.add(column)) {
          availableColumns.add(AvailableColumn(column, availableSource));
        }
      }
    }

    if (availableColumns.isEmpty) {
      return parent.resolveUnqualifiedReference(columnName);
    } else {
      return availableColumns;
    }
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

/// A special intermediate scope used for nodes that don't see columns and
/// tables added to the statement they're in.
///
/// An example for this are subqueries appearing in a `FROM` clause, which can't
/// see outer columns and tables of the select statement.
///
/// Another example is the [InsertStatement.source] of an [InsertStatement],
/// which cannot refer to columns of the table being inserted to of course.
/// Things like `INSERT INTO tbl (col) VALUES (tbl.col)` are not allowed.
class SourceScope extends ReferenceScope with _HasParentScope {
  final StatementScope enclosingStatement;

  SourceScope(this.enclosingStatement);

  @override
  RootScope get rootScope => enclosingStatement.rootScope;

  // This scope can't see elements from the enclosing statement, but it can see
  // elements from grandparents.
  @override
  ReferenceScope get _parentScopeForLookups => enclosingStatement.parent;

  @override
  ResultSet? resolveResultSetToAdd(String name) {
    // CTEs from the enclosing statement are also available here
    return enclosingStatement.resolveResultSetToAdd(name);
  }
}

/// A rarely used sub-scope for AST nodes that belong to a statement, but may
/// have access to more result sets.
///
/// For instance, the body of an `ON CONFLICT DO UPDATE`-clause may refer to a
/// table alias `excluded` to get access to a conflicting table.
class MiscStatementSubScope extends ReferenceScope with _HasParentScope {
  final StatementScope parent;

  @override
  get _parentScopeForLookups => parent;

  final Map<String?, ResultSetAvailableInStatement> additionalResultSets =
      CaseInsensitiveMap();

  MiscStatementSubScope(this.parent);

  @override
  RootScope get rootScope => parent.rootScope;

  @override
  ResultSetAvailableInStatement? resolveResultSetForReference(String name) {
    return additionalResultSets[name] ??
        parent.resolveResultSetForReference(name);
  }

  @override
  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    additionalResultSets[name] = resultSet;
  }
}

/// A reference scope that only allows a single added result set.
///
/// This is used for e.g. foreign key clauses (`REFERENCES table (a, b, c)`),
/// where `a`, `b` and `c` can only refer to `table`.
class SingleTableReferenceScope extends ReferenceScope {
  final ReferenceScope parent;

  final String addedTableName;
  final ResultSetAvailableInStatement? addedTable;

  SingleTableReferenceScope(this.parent, this.addedTableName, this.addedTable);

  @override
  RootScope get rootScope => parent.rootScope;

  @override
  ResultSetAvailableInStatement? resolveResultSetForReference(String name) {
    if (name == addedTableName) {
      return addedTable;
    } else {
      return null;
    }
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
