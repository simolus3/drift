part of 'manager.dart';

class OrderingBuilder {
  /// The mode of the ordering
  final OrderingMode mode;

  /// The column that the ordering is applied to
  final GeneratedColumn column;

  OrderingBuilder(this.mode, this.column);

  @override
  bool operator ==(covariant OrderingBuilder other) {
    if (identical(this, other)) return true;

    return other.mode == mode && other.column == column;
  }

  @override
  int get hashCode => mode.hashCode ^ column.hashCode;

  /// Build a join from this join builder
  OrderingTerm buildTerm() {
    return OrderingTerm(mode: mode, expression: column);
  }
}

/// Defines a class that can be used to compose orderings for a column
class ComposableOrdering implements HasJoinBuilders {
  final Set<OrderingBuilder> orderingBuilders;
  @override
  final Set<JoinBuilder> joinBuilders;
  @override
  void addJoinBuilder(JoinBuilder builder) {
    joinBuilders.add(builder);
  }

  /// Create a new ordering for a column
  ComposableOrdering.simple(this.orderingBuilders) : joinBuilders = {};
  ComposableOrdering.withJoin(this.orderingBuilders, this.joinBuilders);

  ComposableOrdering operator |(ComposableOrdering other) {
    return ComposableOrdering.withJoin(
        orderingBuilders.union(other.orderingBuilders),
        joinBuilders.union(other.joinBuilders));
  }

  /// Build a drift [OrderingTerm] from this ordering
  List<OrderingTerm> buildTerms() => orderingBuilders
      .map((e) => OrderingTerm(mode: e.mode, expression: e.column))
      .toList();
}

/// The class that orchestrates the composition of orderings
class OrderingComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  /// Create a new ordering composer from existing query state
  // OrderingComposer.fromComposer(super.state);

  /// Create an ordering composer with an empty state
  OrderingComposer.empty(super.db, super.table) : super.empty();
  OrderingComposer.withAliasedTable(super.data) : super.withAliasedTable();
}
