part of 'manager.dart';

/// Defines a class that can be used to compose filters for a column
class ColumnFilters<T extends Object> {
  /// This class is a wrapper on top of the generated column class
  ///
  /// It's used to expose filter functions for a column type
  ///
  /// Use an extention to add more filters to any column type
  ///
  /// ```dart
  /// extension on FilterComposer<DateTime>{
  ///  FitlerBuilder after2000() => isAfter(DateTime(2000));
  ///}
  /// ```
  ColumnFilters(this.column);

  /// Column that this [ColumnFilters] wraps
  GeneratedColumn<T> column;

  // ignore: public_member_api_docs
  ComposableFilter isNull() => ComposableFilter.simple(column.isNull());
  // ignore: public_member_api_docs
  ComposableFilter isNotNull() => ComposableFilter.simple(column.isNotNull());
  // ignore: public_member_api_docs
  ComposableFilter equals(T value) =>
      ComposableFilter.simple(column.equals(value));
}

/// Built in filters for int/double columns
extension NumFilters<T extends num> on ColumnFilters<T> {
  // ignore: public_member_api_docs
  ComposableFilter isBiggerThan(T value) =>
      ComposableFilter.simple(column.isBiggerThanValue(value));
// ignore: public_member_api_docs
  ComposableFilter isNotBiggerThan(T value) => isBiggerThan(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isSmallerThan(T value) =>
      ComposableFilter.simple(column.isSmallerThanValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotSmallerThan(T value) =>
      isSmallerThan(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isBiggerOrEqualTo(T value) =>
      ComposableFilter.simple(column.isBiggerOrEqualValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotBiggerOrEqualTo(T value) =>
      isBiggerOrEqualTo(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isSmallerOrEqualTo(T value) =>
      ComposableFilter.simple(column.isSmallerOrEqualValue(value));
// ignore: public_member_api_docs
  ComposableFilter isNotSmallerOrEqualTo(T value) =>
      isSmallerOrEqualTo(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isBetween(T lower, T higher) =>
      ComposableFilter.simple(column.isBetweenValues(lower, higher));
// ignore: public_member_api_docs
  ComposableFilter isNotBetween(T lower, T higher) =>
      isBetween(lower, higher)._reversed();
}

/// Built in filters for BigInt columns
extension BigIntFilters<T extends BigInt> on ColumnFilters<T> {
  // ignore: public_member_api_docs
  ComposableFilter isBiggerThan(T value) =>
      ComposableFilter.simple(column.isBiggerThanValue(value));
// ignore: public_member_api_docs
  ComposableFilter isNotBiggerThan(T value) => isBiggerThan(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isSmallerThan(T value) =>
      ComposableFilter.simple(column.isSmallerThanValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotSmallerThan(T value) =>
      isSmallerThan(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isBiggerOrEqualTo(T value) =>
      ComposableFilter.simple(column.isBiggerOrEqualValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotBiggerOrEqualTo(T value) =>
      isBiggerOrEqualTo(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isSmallerOrEqualTo(T value) =>
      ComposableFilter.simple(column.isSmallerOrEqualValue(value));
// ignore: public_member_api_docs
  ComposableFilter isNotSmallerOrEqualTo(T value) =>
      isSmallerOrEqualTo(value)._reversed();
// ignore: public_member_api_docs
  ComposableFilter isBetween(T lower, T higher) =>
      ComposableFilter.simple(column.isBetweenValues(lower, higher));
// ignore: public_member_api_docs
  ComposableFilter isNotBetween(T lower, T higher) =>
      isBetween(lower, higher)._reversed();
}

/// Built in filters for String columns
extension DateFilters<T extends DateTime> on ColumnFilters<T> {
// ignore: public_member_api_docs
  ComposableFilter isAfter(T value) =>
      ComposableFilter.simple(column.isBiggerThanValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotAfter(T value) => isAfter(value)._reversed();

  // ignore: public_member_api_docs
  ComposableFilter isBefore(T value) =>
      ComposableFilter.simple(column.isSmallerThanValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotBefore(T value) => isBefore(value)._reversed();

  // ignore: public_member_api_docs
  ComposableFilter isAfterOrOn(T value) =>
      ComposableFilter.simple(column.isBiggerOrEqualValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotAfterOrOn(T value) => isAfterOrOn(value)._reversed();

  // ignore: public_member_api_docs
  ComposableFilter isBeforeOrOn(T value) =>
      ComposableFilter.simple(column.isSmallerOrEqualValue(value));
  // ignore: public_member_api_docs
  ComposableFilter isNotBeforeOrOn(T value) => isBeforeOrOn(value)._reversed();

  // ignore: public_member_api_docs
  ComposableFilter isBetween(T lower, T higher) =>
      ComposableFilter.simple(column.isBetweenValues(lower, higher));
  // ignore: public_member_api_docs
  ComposableFilter isNotBetween(T lower, T higher) =>
      isBetween(lower, higher)._reversed();
}

/// Defines a class that can be used to compose filters for a column
class ComposableFilter implements HasJoinBuilders {
  @override
  final Set<JoinBuilder> joinBuilders;
  @override
  void addJoinBuilder(JoinBuilder builder) {
    joinBuilders.add(builder);
  }

  /// The expression that will be applied to the query
  final Expression<bool> expression;

  /// This class is wrapper on expression class
  ///
  /// It contains the expression, along with any joins that are required
  /// to execute the expression
  ///
  /// It also contains a list of aliases that were used in joins
  /// This will be used to ensure that the same alias isn't used twice
  ComposableFilter.withJoin(
    this.expression,
    this.joinBuilders,
  );

  // ignore: public_member_api_docs
  ComposableFilter.simple(this.expression) : joinBuilders = {};

  /// Combine two filters with an AND
  ComposableFilter operator &(ComposableFilter other) {
    return ComposableFilter.withJoin(
      expression & other.expression,
      joinBuilders.union(other.joinBuilders),
    );
  }

  /// Combine two filters with an OR
  ComposableFilter operator |(ComposableFilter other) {
    return ComposableFilter.withJoin(
      expression | other.expression,
      joinBuilders.union(other.joinBuilders),
    );
  }

  /// Returns a copy of this filter with the expression reversed
  ComposableFilter _reversed() {
    return ComposableFilter.withJoin(
      expression.not(),
      joinBuilders,
    );
  }

  /// Returns a copy of this filter with the given joins and usedAliases
  ComposableFilter copyWithJoins(Set<JoinBuilder> joinBuilders) {
    return ComposableFilter.withJoin(
        expression, joinBuilders.union(this.joinBuilders));
  }
}

/// The class that orchestrates the composition of filtering
class FilterComposer<DB extends GeneratedDatabase, T extends TableInfo>
    extends Composer<DB, T> {
  /// Create a new filter composer from existing query state
  // FilterComposer(super.state);

  /// Create a filter composer with an empty state
  FilterComposer.empty(super.db, super.table) : super.empty();
  FilterComposer.withAliasedTable(super.data) : super.withAliasedTable();
}
