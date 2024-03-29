part of 'manager.dart';

/// A class that contains the information needed to create a join
@internal
class JoinBuilder {
  /// The table that the join is being applied to
  final Table currentTable;

  /// The referenced table that will be joined
  final Table referencedTable;

  /// The column of the current database which will be use to create the join
  final GeneratedColumn currentColumn;

  /// The column of the referenced database which will be use to create the join

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

    return other.aliasedName == aliasedName;
  }

  @override
  int get hashCode {
    return aliasedName.hashCode;
  }

  /// Build a join from this join builder
  Join buildJoin() {
    return leftOuterJoin(
        referencedTable, currentColumn.equalsExp(referencedColumn));
  }
}

/// An interface for classes that hold join builders
@internal
abstract interface class HasJoinBuilders {
  /// The join builders that are associated with this class
  Set<JoinBuilder> get joinBuilders;

  /// Add a join builder to this class
  void addJoinBuilder(JoinBuilder builder);
}

/// Helper for getting all the aliased names of a set of join builders
extension on Set<JoinBuilder> {
  List<String> get aliasedNames => map((e) => (e.aliasedName)).toList();
}
