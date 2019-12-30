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

  Column();

  @override
  String humanReadableDescription() {
    return name;
  }
}

/// A column that is part of a table.
class TableColumn extends Column {
  @override
  final String name;

  /// The type of this column, which is available before any resolution happens
  /// (we know if from the table).
  final ResolvedType type;

  /// The column constraints set on this column.
  ///
  /// This only works columns where [hasDefinition] is true, otherwise this
  /// getter will throw. The columns in a `CREATE TABLE` statement always have
  /// a definition, but those from a `CREATE VIRTUAL TABLE` likely don't.
  ///
  /// See also:
  /// - https://www.sqlite.org/syntax/column-constraint.html
  List<ColumnConstraint> get constraints => definition.constraints;

  /// The definition in the AST that was used to create this column model.
  final ColumnDefinition definition;

  /// Whether this column has a definition from the ast.
  bool get hasDefinition => definition != null;

  /// The table this column belongs to.
  Table table;

  TableColumn(this.name, this.type, {this.definition});

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
    if (definition == null ||
        table == null ||
        type?.type != BasicType.int ||
        table.withoutRowId) {
      return false;
    }

    // We need to check whether this column is a primary key, which could happen
    // because of a table or a column constraint
    final columnsWithKey = table.tableConstraints.whereType<KeyClause>();
    for (final tableConstraint in columnsWithKey) {
      if (!tableConstraint.isPrimaryKey) continue;

      final columns = tableConstraint.indexedColumns;
      if (columns.length == 1 && columns.single.columnName == name) {
        return true;
      }
    }

    // option 2: This column has a primary key constraint
    for (final primaryConstraint in constraints.whereType<PrimaryKeyColumn>()) {
      if (primaryConstraint.mode == OrderingMode.descending) return false;

      // additional restriction: Column type must be exactly "INTEGER"
      return definition.typeName == 'INTEGER';
    }

    return false;
  }

  @override
  String humanReadableDescription() {
    return '$name in ${table.humanReadableDescription()}';
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

  ExpressionColumn({@required this.name, this.expression});
}

/// A column that is created by a reference expression. The difference to an
/// [ExpressionColumn] is that the correct case of the column name depends on
/// the resolved reference.
class ReferenceExpressionColumn extends ExpressionColumn {
  Reference get reference => expression as Reference;

  @override
  String get name => overriddenName ?? reference.resolvedColumn?.name;

  final String overriddenName;

  ReferenceExpressionColumn(Reference ref, {this.overriddenName})
      : super(name: null, expression: ref);
}

/// A column that wraps another column.
mixin DelegatedColumn on Column {
  Column get innerColumn;

  @override
  String get name => innerColumn.name;
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
  Column innerColumn;

  // note that innerColumn is mutable because the column might not be known
  // during all analysis phases.

  CommonTableExpressionColumn(this.name, this.innerColumn);
}
