part of '../analysis.dart';

/// A column that appears in a [ResultSet]. Has a type and a name.
abstract class Column
    with Referencable, HasMetaMixin
    implements Typeable, HumanReadable {
  /// The name of this column in the result set.
  String get name;

  /// Whether this column is included in results when running a select query
  /// like `SELECT * FROM table`.
  ///
  /// Some columns, notably the rowid aliases, are exempt from this.
  bool get includedInResults => true;

  /// The result set containing this column, or null if this column is not part
  /// of a known result set.
  ResultSet? containingSet;

  @override
  String humanReadableDescription() {
    return name;
  }
}

/// A column that has a statically known resolved type.
abstract interface class ColumnWithType implements Column {
  /// The type of this column, which is available before any resolution happens
  /// (we know it from the schema structure).
  ResolvedType? get type;
}

/// A column that is part of a table.
class TableColumn extends Column implements ColumnWithType {
  @override
  final String name;

  /// Whether this column was created with a `GENERATED ALWAYS AS` column
  /// constraint.
  ///
  /// Generated columns can't be inserted or updated.
  final bool isGenerated;

  /// Whether this column is `HIDDEN`, as specified in
  /// https://www.sqlite.org/vtab.html#hidden_columns_in_virtual_tables
  final bool isHidden;

  @override
  ResultSet? get containingSet => table;

  @override
  ResolvedType get type => _type;
  ResolvedType _type;

  /// The column constraints set on this column.
  ///
  /// This only works columns where [hasDefinition] is true, otherwise this
  /// getter will throw. The columns in a `CREATE TABLE` statement always have
  /// a definition, but those from a `CREATE VIRTUAL TABLE` likely don't.
  ///
  /// See also:
  /// - https://www.sqlite.org/syntax/column-constraint.html
  List<ColumnConstraint> get constraints => definition!.constraints;

  /// The definition in the AST that was used to create this column model.
  final ColumnDefinition? definition;

  /// Whether this column has a definition from the ast.
  bool get hasDefinition => definition != null;

  /// The table this column belongs to.
  Table? table;

  late final bool _isAliasForRowId = _computeIsAliasForRowId();

  TableColumn(
    this.name,
    this._type, {
    this.definition,
    this.isGenerated = false,
    this.isHidden = false,
  });

  @override
  bool get includedInResults => !isHidden;

  /// Applies a type hint to this column.
  ///
  /// The [hint] will then be reflected in the [type].
  void applyTypeHint(TypeHint hint) {
    _type = _type.addHint(hint);
  }

  /// Whether this column is an alias for the rowid, as defined in
  /// https://www.sqlite.org/lang_createtable.html#rowid
  ///
  /// To summarize, a column is an alias for the rowid if all of the following
  /// conditions are met:
  /// - the table has a primary key that consists of exactly one (this) column
  /// - the column is declared to be an integer
  /// - if this column has a [PrimaryKeyColumn], the [OrderingMode] of that
  ///   constraint is not [OrderingMode.descending].
  bool isAliasForRowId() {
    return _isAliasForRowId;
  }

  bool _computeIsAliasForRowId() {
    if (definition == null ||
        table == null ||
        type.type != BasicType.int ||
        table!.withoutRowId) {
      return false;
    }

    // We need to check whether this column is a primary key, which could happen
    // because of a table or a column constraint
    final columnsWithKey = table!.tableConstraints.whereType<KeyClause>();
    for (final tableConstraint in columnsWithKey) {
      if (!tableConstraint.isPrimaryKey) continue;

      final columns = tableConstraint.columns;
      if (columns.length != 1) continue;

      final singleColumnExpr = columns.single.expression;

      if (singleColumnExpr is Reference &&
          singleColumnExpr.columnName == name) {
        return true;
      }
    }

    // option 2: This column has a primary key constraint
    for (final primaryConstraint in constraints.whereType<PrimaryKeyColumn>()) {
      if (primaryConstraint.mode == OrderingMode.descending) return false;

      // additional restriction: Column type must be exactly "INTEGER"
      return definition!.typeName == 'INTEGER';
    }

    return false;
  }

  @override
  String humanReadableDescription() {
    return '$name in ${table!.humanReadableDescription()}';
  }
}

/// A column that is part of a view.
class ViewColumn extends Column with DelegatedColumn implements ColumnWithType {
  final String? _name;

  @override
  final ResolvedType? type;

  @override
  final Column innerColumn;

  @override
  ResultSet? get containingSet => view;

  /// The view this column belongs to.
  View? view;

  /// Creates a view column wrapping a [Column] from the select statement used
  /// to create the view.
  ///
  /// The optional name parameter can be used to override the name for this
  /// column. By default, the name of the [innerColumn] will be used.
  ViewColumn(this.innerColumn, this.type, [this._name]);

  @override
  String get name => _name ?? super.name;

  @override
  String humanReadableDescription() {
    return '$name in ${view!.humanReadableDescription()}';
  }
}

/// Refers to the special "rowid", "oid" or "_rowid_" column defined for tables
/// that weren't created with an `WITHOUT ROWID` clause.
class RowId extends TableColumn {
  // note that such alias is always called "rowid" in the result set -
  // "SELECT oid FROM table" yields a sinle column called "rowid"
  RowId() : super('rowid', const ResolvedType(type: BasicType.int));

  @override
  bool get includedInResults => false;
}

/// A column that is created by an expression. For instance, in the select
/// statement "SELECT 1 + 3", there is a column called "1 + 3" of type int.
class ExpressionColumn extends Column {
  @override
  final String name;

  /// The expression returned by this column.
  final Expression expression;

  /// When drift extensions are enabled and this column was defined with a
  /// `MAPPED BY` clause, a reference to that clause.
  final MappedBy? mappedBy;

  ExpressionColumn({
    required this.name,
    required this.expression,
    this.mappedBy,
  });
}

/// A column that is created by a reference expression. The difference to an
/// [ExpressionColumn] is that the correct case of the column name depends on
/// the resolved reference.
class ReferenceExpressionColumn extends ExpressionColumn {
  Reference? get reference => expression as Reference?;

  @override
  String get name {
    return overriddenName ??
        reference!.resolvedColumn?.name ??
        // The resolved column might not have been resolved yet. Use the
        // syntactic name from the reference as a fallback: It's only different
        // for rowid references, and those are easier to resolve.
        reference!.columnName;
  }

  final String? overriddenName;

  ReferenceExpressionColumn(Reference ref,
      {this.overriddenName, super.mappedBy})
      : super(name: '_', expression: ref);
}

/// A column that wraps another column.
mixin DelegatedColumn on Column {
  Column? get innerColumn;

  @override
  String get name => innerColumn!.name;

  @override
  bool get includedInResults => innerColumn?.includedInResults ?? true;
}

/// The result column of a [CompoundSelectStatement].
class CompoundSelectColumn extends Column with DelegatedColumn {
  /// The column in [CompoundSelectStatement.base] each of the
  /// [CompoundSelectStatement.additional] that contributed to this column.
  final List<Column> columns;

  CompoundSelectColumn(this.columns);

  @override
  Column get innerColumn => columns.first;
}

class CommonTableExpressionColumn extends Column with DelegatedColumn {
  @override
  final String name;

  @override
  Column? innerColumn;

  // note that innerColumn is mutable because the column might not be known
  // during all analysis phases.

  CommonTableExpressionColumn(this.name, [this.innerColumn]);
}

/// Result column coming from a `VALUES` select statement.
class ValuesSelectColumn extends Column {
  @override
  final String name;

  /// The expressions from a `VALUES` clause contributing to this column.
  ///
  /// Essentially, each [ValuesSelectColumn] consists of a column in the values
  /// of a [ValuesSelectStatement].
  final List<Expression> expressions;

  ValuesSelectColumn(this.name, this.expressions)
      : assert(expressions.isNotEmpty);
}

/// A column that is available in the scope of a statement.
///
/// In addition to the [innerColumn], this provides the [source] which brought
/// this column into scope. This can be used to determine nullability.
class AvailableColumn extends Column with DelegatedColumn {
  @override
  final Column innerColumn;
  final ResultSetAvailableInStatement source;

  AvailableColumn(this.innerColumn, this.source);
}

extension UnaliasColumn on Column {
  /// Attempts to resolve the source of this column, if this is an
  /// [AvailableColumn] or a [CommonTableExpressionColumn] that refers to
  /// another column.
  Column get source {
    var current = this;
    while (current is DelegatedColumn) {
      final inner = current.innerColumn;
      if (inner != null) {
        current = inner;
      } else {
        return current;
      }
    }

    return current;
  }
}
