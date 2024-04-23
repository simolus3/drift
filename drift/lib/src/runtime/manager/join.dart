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

/// An interface for classes that hold join builders
/// Typically used by classes whose composition requires joins
/// to be created
///
/// Example:
/// ```dart
/// categories.filter((f) => f.todos((f) => f.dueDate.isBefore(DateTime.now())))
/// ```
///
/// In the above example, f.todos() returns a [ComposableFilter] object, which
/// is a subclass of [HasJoinBuilders].
/// This resulting where expression will require a join to be created
/// between the `categories` and `todos` table.
///
/// This interface is used to ensure that the [ComposableFilter] object will have
/// the information needed to create the join.
@internal
abstract interface class HasJoinBuilders {
  /// The join builders that are associated with this class
  Set<JoinBuilder> get joinBuilders;

  /// Add a join builder to this class
  void addJoinBuilders(Set<JoinBuilder> builders) {
    joinBuilders.addAll(builders);
  }
}
