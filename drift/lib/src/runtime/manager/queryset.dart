part of 'manager.dart';

/// A class that contains the information needed to create a join
@internal
class JoinBuilder {
  /// The table that the join is being applied to
  final Table currentTable;

  /// The referenced table that will be joined
  final Table referencedTable;

  /// The column of the [currentTable] which will be use to create the join
  final GeneratedColumn currentColumn;

  /// The column of the [referencedTable] which will be use to create the join
  final GeneratedColumn referencedColumn;

  /// Class that describes how a ordering that is being
  /// applied to a referenced table
  /// should be joined to the current table
  JoinBuilder(
      {required this.currentTable,
      required this.referencedTable,
      required this.currentColumn,
      required this.referencedColumn});

  /// The name of the alias that this join will use
  String get aliasedName {
    return referencedColumn.tableName;
  }

  @override
  bool operator ==(covariant JoinBuilder other) {
    if (identical(this, other)) return true;

    return other.currentColumn == currentColumn &&
        other.referencedColumn == referencedColumn;
  }

  @override
  int get hashCode {
    return currentColumn.hashCode ^ referencedColumn.hashCode;
  }

  /// Build a join from this join builder
  Join buildJoin() {
    return leftOuterJoin(
        referencedTable, currentColumn.equalsExp(referencedColumn),
        useColumns: false);
  }
}

/// A class that contains the information needed to create a group by
@internal
class GroupByBuilder {
  final Iterable<Expression> expressions;
  final Expression<bool>? having;
  GroupByBuilder(this.expressions, {this.having});
  GroupByBuilder copyWith({required Expression<bool>? having}) {
    return GroupByBuilder(expressions, having: having);
  }
}

/// An interface for classes which need to hold the information needed to create
/// orderings or where expressions.
///
/// Example:
/// ```dart
/// todos.filter((f) => f.category )
/// ```
///
/// In the above example, f.category returns a [ComposableFilter] object, which
/// is a subclass of [Queryset].
/// This resulting where expression will require a join to be created
/// between the `categories` and `todos` table.
///
/// This interface is used to ensure that the [ComposableFilter] object will have
/// the information needed to create the join/group by expressions.
@internal
abstract interface class Queryset {
  /// The join builders that are associated with this class
  /// They are ordered by the order in which they were added
  /// These will be used by the [TableManagerState] to create the joins
  /// that are needed to create the where expression
  Set<JoinBuilder> get joinBuilders;

  /// The group by builders that are associated with this class
  /// They are ordered by the order in which they were added
  /// These will be used by the [TableManagerState] to create the group by's
  /// which  will be used to filter the results
  List<GroupByBuilder> get groupByBuilders;
}
