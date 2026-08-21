import 'package:drift3_preview/drift.dart';
import 'package:meta/meta.dart';

/// Defines a class which is used to wrap a column to only expose ordering functions
class ColumnOrderings<T extends Object> {
  /// This class is a wrapper on top of the generated column class
  ///
  /// It's used to expose ordering functions for a column
  ///
  /// {@macro manager_internal_use_only}
  ColumnOrderings(this.column);

  /// Column that this [ColumnOrderings] wraps
  Expression<T> column;

  /// Create a new [ComposableOrdering] for this column.
  /// This is used to create lower level orderings
  /// that can be composed together
  ComposableOrdering $composableOrdering(Set<OrderingBuilder> orderings) {
    return ComposableOrdering._(orderings);
  }

  /// Sort this column in ascending order (1 -> 10 | A -> Z | Jan 1 -> Dec 31).
  ///
  /// The optional [nulls] parameter can be used to control whether `NULL`
  /// values in the column should come for or after non-null values.
  ComposableOrdering asc({NullsOrder? nulls}) => $composableOrdering({
    OrderingBuilder(OrderingMode.asc, column, nulls: nulls),
  });

  /// Sort this column in descending order (10 -> 1 | Z -> A | Dec 31 -> Jan 1).
  ///
  /// The optional [nulls] parameter can be used to control whether `NULL`
  /// values in the column should come for or after non-null values.
  ComposableOrdering desc({NullsOrder? nulls}) => $composableOrdering({
    OrderingBuilder(OrderingMode.desc, column, nulls: nulls),
  });
}

/// Defines a class which will hold the information needed to create an ordering
final class OrderingBuilder {
  /// The mode of the ordering
  final OrderingMode mode;

  /// The column that the ordering is applied to
  final Expression<Object> column;

  /// How null values are treated in the ordering.
  final NullsOrder? nulls;

  /// Create a new ordering builder, will be used by the [TableManagerState] to create [OrderingTerm]s
  @internal
  OrderingBuilder(this.mode, this.column, {this.nulls});

  @override
  bool operator ==(covariant OrderingBuilder other) {
    if (identical(this, other)) return true;

    return other.mode == mode && other.column == column && other.nulls == nulls;
  }

  @override
  int get hashCode => Object.hash(mode, column, nulls);

  /// Build the ordering term using the expression and direction
  OrderingTerm buildTerm() {
    return OrderingTerm(mode: mode, expression: column, nulls: nulls);
  }
}

/// Defines a class that can be used to compose orderings for a column
///
/// Multiple orderings can be composed together using the `&` operator.
/// The orderings will be executed from left to right.

final class ComposableOrdering {
  /// The orderings that are being composed
  final Set<OrderingBuilder> orderingBuilders;

  /// Create a new [ComposableOrdering] for a column
  ComposableOrdering._(this.orderingBuilders);

  /// Combine two orderings with THEN
  ComposableOrdering operator &(ComposableOrdering other) {
    return ComposableOrdering._(orderingBuilders.union(other.orderingBuilders));
  }

  /// Build a drift [OrderingTerm] from this ordering
  List<OrderingTerm> buildTerms() => orderingBuilders
      .map((e) => OrderingTerm(mode: e.mode, expression: e.column))
      .toList();
}
