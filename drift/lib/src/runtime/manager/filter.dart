part of 'manager.dart';

/// Defines a class which is used to wrap a column to only expose filter functions
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
  const ColumnFilters(this.column);

  /// Column that this [ColumnFilters] wraps
  final Expression<T> column;

  /// Create a filter that checks if the column is null.
  ComposableFilter isNull() => ComposableFilter(column.isNull());

  /// Create a filter that checks if the column is not null.
  ComposableFilter isNotNull() => ComposableFilter(column.isNotNull());

  /// Create a filter that checks if the column equals a value.
  ComposableFilter equals(T value) => ComposableFilter(column.equals(value));

  /// Create a filter that checks if the column is in a list of values.

  ComposableFilter isIn(Iterable<T> values) =>
      ComposableFilter(column.isIn(values));

  /// Create a filter that checks if the column is not in a list of values.
  ComposableFilter isNotIn(Iterable<T> values) =>
      ComposableFilter(column.isNotIn(values));

  /// Shortcut for [equals]
  ComposableFilter call(T value) => ComposableFilter(column.equals(value));

  /// Nested column for filtering on the count of a column
  ColumnFilters<int> get count => ColumnFilters(column.count());
}

/// Built in filters for bool columns
extension BoolFilters on ColumnFilters<bool> {
  /// Create a filter to check if the column is bigger than a value
  ComposableFilter isTrue(bool value) => ComposableFilter(column.equals(true));

  /// Create a filter to check if the column is small than a value
  ComposableFilter isFalse(bool value) => ComposableFilter(column.equals(true));
}

/// Built in filters for int/double columns
extension NumFilters<T extends num> on ColumnFilters<T> {
  /// Create a filter to check if the column is bigger than a value
  ComposableFilter isBiggerThan(T value) =>
      ComposableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is small than a value
  ComposableFilter isSmallerThan(T value) =>
      ComposableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is bigger or equal to a value
  ComposableFilter isBiggerOrEqualTo(T value) =>
      ComposableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is small or equal to a value
  ComposableFilter isSmallerOrEqualTo(T value) =>
      ComposableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between two values
  ComposableFilter isBetween(T lower, T higher) =>
      ComposableFilter(column.isBetweenValues(lower, higher));

  /// Create a filter to check if the column is not between two values
  ComposableFilter isNotBetween(T lower, T higher) =>
      isBetween(lower, higher)._invert();

  /// Nested column for filtering on the average of a column
  ColumnFilters<double> get avg => ColumnFilters(column.avg());

  /// Nested column for filtering on the max item of a column
  ColumnFilters<T> get max => ColumnFilters(column.max());

  /// Nested column for filtering on the min item of a column
  ColumnFilters<T> get min => ColumnFilters(column.min());

  /// Nested column for filtering on the sum of a column
  ColumnFilters<T> get sum => ColumnFilters(column.sum());

  /// Nested column for filtering on the total of a column
  ColumnFilters<double> get total => ColumnFilters(column.total());
}

/// Built in filters for BigInt columns
extension BigIntFilters<T extends BigInt> on ColumnFilters<T> {
  /// Create a filter to check if the column is bigger than a value
  ComposableFilter isBiggerThan(T value) =>
      ComposableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is small than a value
  ComposableFilter isSmallerThan(T value) =>
      ComposableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is bigger or equal to a value
  ComposableFilter isBiggerOrEqualTo(T value) =>
      ComposableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is small or equal to a value
  ComposableFilter isSmallerOrEqualTo(T value) =>
      ComposableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between two values
  ComposableFilter isBetween(T lower, T higher) =>
      ComposableFilter(column.isBetweenValues(lower, higher));

  /// Create a filter to check if the column is not between two values
  ComposableFilter isNotBetween(T lower, T higher) =>
      isBetween(lower, higher)._invert();

  /// Nested column for filtering on the average of a column
  ColumnFilters<double> get avg => ColumnFilters(column.avg());

  /// Nested column for filtering on the max item of a column
  ColumnFilters<T> get max => ColumnFilters(column.max());

  /// Nested column for filtering on the min item of a column
  ColumnFilters<T> get min => ColumnFilters(column.min());

  /// Nested column for filtering on the sum of a column
  ColumnFilters<BigInt> get sum => ColumnFilters(column.sum());

  /// Nested column for filtering on the total of a column
  ColumnFilters<double> get total => ColumnFilters(column.total());
}

/// Built in filters for String columns
extension DateFilters<T extends DateTime> on ColumnFilters<T> {
  /// Create a filter to check if the column is after a [DateTime]
  ComposableFilter isAfter(T value) =>
      ComposableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is before a [DateTime]
  ComposableFilter isBefore(T value) =>
      ComposableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is on or after a [DateTime]
  ComposableFilter isAfterOrOn(T value) =>
      ComposableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is before or on a [DateTime]
  ComposableFilter isBeforeOrOn(T value) =>
      ComposableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between 2 [DateTime]s

  ComposableFilter isBetween(T lower, T higher) =>
      ComposableFilter(column.isBetweenValues(lower, higher));

  /// Create a filter to check if the column is not between 2 [DateTime]s
  ComposableFilter isNotBetween(T lower, T higher) =>
      isBetween(lower, higher)._invert();
}

/// Defines a class which is used to wrap a column with a type converter to only expose filter functions
class ColumnWithTypeConverterFilters<CUSTOM, T extends Object> {
  /// Similar to [ColumnFilters] but for columns with type converters\
  const ColumnWithTypeConverterFilters(this.column);

  /// Column that this [ColumnWithTypeConverterFilters] wraps
  final GeneratedColumnWithTypeConverter<CUSTOM, T> column;

  /// Create a filter that checks if the column is null.
  ComposableFilter isNull() => ComposableFilter(column.isNull());

  /// Create a filter that checks if the column is not null.
  ComposableFilter isNotNull() => ComposableFilter(column.isNotNull());

  /// Create a filter that checks if the column equals a value.
  ComposableFilter equals(CUSTOM value) =>
      ComposableFilter(column.equalsValue(value));

  /// Shortcut for [equals]
  ComposableFilter call(CUSTOM value) =>
      ComposableFilter(column.equalsValue(value));
}

/// This class is wrapper on the expression class
///
/// It contains the expression, along with any joins that are required
/// to execute the expression. See [HasJoinBuilders] for more information
/// on how joins are stored
class ComposableFilter extends HasJoinBuilders {
  @override
  final Set<JoinBuilder> joinBuilders;

  /// The expression that will be applied to the query
  final Expression<bool> expression;

  /// Create a new [ComposableFilter] for a column without any joins
  ComposableFilter(this.expression) : joinBuilders = {};

  /// Create a new [ComposableFilter] for a column with joins
  ComposableFilter._(this.expression, this.joinBuilders);

  /// Combine two filters with an AND
  ComposableFilter operator &(ComposableFilter other) {
    return ComposableFilter._(
      expression & other.expression,
      joinBuilders.union(other.joinBuilders),
    );
  }

  /// Combine two filters with an OR
  ComposableFilter operator |(ComposableFilter other) {
    return ComposableFilter._(
      expression | other.expression,
      joinBuilders.union(other.joinBuilders),
    );
  }

  /// Returns a copy of this filter with the expression reversed
  ComposableFilter _invert() {
    return ComposableFilter._(
      expression.not(),
      joinBuilders,
    );
  }
}

/// The class that orchestrates the composition of filtering
class FilterComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  /// Create a filter composer with an empty state
  FilterComposer(super.$db, super.$table);
}
