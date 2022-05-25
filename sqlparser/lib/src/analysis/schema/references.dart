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

abstract class ReferenceScope {
  RootScope get rootScope;

  List<Column>? get expansionOfStarColumn => null;

  /// Attempts to find a result set that has been added to this scope, for
  /// instance because it was introduced in a `FROM` clause.
  ///
  /// This is useful to resolve qualified references (e.g. to resolve `foo.bar`
  /// the resolver would call [resolveResultSet]("foo") and then look up the
  /// `bar` column in that result set).
  ResultSetAvailableInStatement? resolveResultSet(String name) => null;

  void addResolvedResultSet(
      String? name, ResultSetAvailableInStatement resultSet) {
    throw StateError('Result set cannot be added in this scope: $this');
  }

  /// Registers a [ResultSetAvailableInStatement] to a [TableAlias] for the
  /// given [resultSet].
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

  List<Column> resolveUnqualifiedReference(String columnName,
          {bool allowReferenceToResultColumn = false}) =>
      const [];
}

class RootScope extends ReferenceScope {
  @override
  RootScope get rootScope => this;

  final Map<String, ResultSet> knownTables = CaseInsensitiveMap();
  final Map<String, Module> knownModules = CaseInsensitiveMap();
}

class StatementScope extends ReferenceScope {
  final ReferenceScope parent;

  final Map<String, ResultSet> additionalKnownTables = CaseInsensitiveMap();
  final Map<String?, ResultSetAvailableInStatement> resultSets =
      CaseInsensitiveMap();
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
    } else if (parent is SubqueryInFromScope) {
      return parent.enclosingStatement;
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

class SubqueryInFromScope extends ReferenceScope {
  final StatementScope enclosingStatement;

  SubqueryInFromScope(this.enclosingStatement);

  @override
  RootScope get rootScope => enclosingStatement.rootScope;
}

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
