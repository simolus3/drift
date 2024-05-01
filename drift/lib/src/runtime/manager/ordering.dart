part of 'manager.dart';

/// Defines a class which is used to wrap a column to only expose ordering functions
@internal
class ColumnOrderings<T extends Object> {
  /// This class is a wrapper on top of the generated column class
  ///
  /// It's used to expose ordering functions for a column

  ColumnOrderings(this.column, {this.joinBuilders});

  /// Column that this [ColumnOrderings] wraps
  Expression<T> column;

  /// If this column is part of a join, this will hold the join builder
  final Set<JoinBuilder>? joinBuilders;

  /// Create a new [ComposableOrdering] for this column.
  /// This is used to create lower level orderings
  /// that can be composed together
  ComposableOrdering $composableOrdering(Set<OrderingBuilder> orderings) {
    return ComposableOrdering._(orderings, joinBuilders ?? {});
  }

  /// Sort this column in ascending order
  ///
  /// 10 -> 1 | Z -> A | Dec 31 -> Jan 1
  ComposableOrdering asc() =>
      $composableOrdering({OrderingBuilder(OrderingMode.asc, column)});

  /// Sort this column in descending order
  ///
  ///  1 -> 10 | A -> Z | Jan 1 -> Dec 31
  ComposableOrdering desc() =>
      $composableOrdering({OrderingBuilder(OrderingMode.desc, column)});
}

/// Defines a class which will hold the information needed to create an ordering
@internal
class OrderingBuilder {
  /// The mode of the ordering
  final OrderingMode mode;

  /// The column that the ordering is applied to
  final Expression<Object> column;

  /// Create a new ordering builder, will be used by the [TableManagerState] to create [OrderingTerm]s
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
///
/// Multiple orderings can be composed together using the `&` operator.
/// The orderings will be executed from left to right.
/// See [Composable] for more information
/// on how joins are stored
@internal
class ComposableOrdering extends Composable {
  /// The orderings that are being composed
  final Set<OrderingBuilder> orderingBuilders;
  @override
  final Set<JoinBuilder> joinBuilders;

  /// Create a new [ComposableOrdering] for a column with joins
  ComposableOrdering._(this.orderingBuilders, this.joinBuilders);

  /// Combine two orderings with THEN
  ComposableOrdering operator &(ComposableOrdering other) {
    return ComposableOrdering._(orderingBuilders.union(other.orderingBuilders),
        joinBuilders.union(other.joinBuilders));
  }

  /// Build a drift [OrderingTerm] from this ordering
  List<OrderingTerm> buildTerms() => orderingBuilders
      .map((e) => OrderingTerm(mode: e.mode, expression: e.column))
      .toList();
}

/// The class that orchestrates the composition of orderings
@internal
class OrderingComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  /// A ordering composer will be generated for each table.
  /// Each field on the table will return a [ColumnOrderings] object
  /// ```dart
  /// todos.orderBy((f) => f.name.asc());
  /// ```
  /// In the above example, `f` is a [OrderingComposer] object, and `f.name` returns a [ColumnOrderings] object.
  OrderingComposer(super.$state);
}
