part of 'manager.dart';

/// A class that contains the information needed to create a join
class JoinBuilder {
  /// The table that the join is being applied to
  final Table currentTable;

  /// The referenced table that will be joined
  final Table referencedTable;

  /// The column of the [currentTable] which will be use to create the join
  final GeneratedColumn currentColumn;

  /// The column of the [referencedTable] which will be use to create the join
  final GeneratedColumn referencedColumn;

  /// Whether this join should be used to read columns from the referenced table
  final bool useColumns;

  /// Class that describes how a ordering that is being
  /// applied to a referenced table
  /// should be joined to the current table
  @internal
  JoinBuilder(
      {required this.currentTable,
      required this.referencedTable,
      required this.currentColumn,
      required this.referencedColumn,
      this.useColumns = false});

  /// The name of the alias that this join will use
  String get aliasedName {
    return referencedColumn.tableName;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is JoinBuilder) {
      return other.currentColumn == currentColumn &&
          other.referencedColumn == referencedColumn &&
          other.useColumns == useColumns;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    return Object.hash(currentColumn, referencedColumn);
  }

  @override
  String toString() {
    return 'Join between $currentTable and $referencedTable';
  }

  /// Build a join from this join builder
  Join buildJoin() {
    return leftOuterJoin(
        referencedTable, currentColumn.equalsExp(referencedColumn),
        useColumns: useColumns);
  }
}
