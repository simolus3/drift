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
  /// extension on ColumnFilters<DateTime>{
  ///  ComposableFilter after2000() => isAfter(DateTime(2000));
  ///}
  /// ```
  const ColumnFilters(this.column, [this.inverted = false, this._joinBuilder]);

  /// Column that this [ColumnFilters] wraps
  final Expression<T> column;

  /// If true, all filters will be inverted
  final bool inverted;

  /// If this column is part of a join, this will hold the join builder
  final JoinBuilder? _joinBuilder;

  /// Returns a copy of these column filters where all the filters are inverted
  /// ```dart
  /// myColumn.not.equals(5); // All columns that aren't null and have a value that is not equal to 5
  /// ```
  /// Keep in mind that while using inverted filters, null is never returned.
  ///
  /// If you would like to include them, use the [isNull] filter as well
  /// ```dart
  /// myColumn.not.equals(5) | myColumn.isNull(); // All columns that are null OR have a value that is not equal to 5 will be returned
  /// ```
  ColumnFilters<T> get not => ColumnFilters(column, !inverted, _joinBuilder);

  /// Create a composable filter from an expression, this is used to create
  /// lower level filters that can be composed together.
  ComposableFilter $composableFilter(Expression<bool> expression) {
    return ComposableFilter._(inverted ? expression.not() : expression,
        _joinBuilder != null ? {_joinBuilder} : {});
  }

  /// Create a filter that checks if the column equals a value.
  ComposableFilter equals(T value) => $composableFilter(column.equals(value));

  /// Create a filter that checks if the column is null.
  ComposableFilter isNull() => $composableFilter(column.isNull());

  /// Create a filter that checks if the column is in a list of values.
  ComposableFilter isIn(Iterable<T> values) =>
      $composableFilter(column.isIn(values));

  /// Shortcut for [equals]
  ComposableFilter call(T value) => equals(value);
}

enum _StringFilterTypes { contains, startsWith, endsWith }

/// Built in filters for int/double columns
extension StringFilters<T extends String> on ColumnFilters<String> {
  /// This function helps handle case insensitivity in like expressions
  /// This helps handle all the possible scenarios:
  /// 1. If a user hasn't set the database to be case sensitive in like expressions
  ///    Then we are ok with having the query be performed on upper case values
  /// 2. If a user has set the database to be case sensitive in like expressions
  ///    We still can perform a case insensitive search by default. We have all filters
  ///    use `{bool caseInsensitive = true}` which will perform a case insensitive search
  /// 3. If a user has set the database to be case sensitive in like expressions and wan't
  ///    to perform a case sensitive search, they can pass `caseInsensitive = false` manually
  ///
  /// We are using the default of {bool caseInsensitive = true}, so that users who haven't set
  /// the database to be case sensitive wont be confues why their like expressions are case insensitive
  Expression<bool> _buildExpression(
      _StringFilterTypes type, String value, bool caseInsensitive) {
    final Expression<String> column;
    if (caseInsensitive) {
      value = value.toUpperCase();
      column = this.column.upper();
    } else {
      column = this.column;
    }
    switch (type) {
      case _StringFilterTypes.contains:
        return column.like('%$value%');
      case _StringFilterTypes.startsWith:
        return column.like('$value%');
      case _StringFilterTypes.endsWith:
        return column.like('%$value');
    }
  }

  /// Create a filter to check if the this text column contains a substring
  ///
  /// Setting [caseInsensitive] to false will have no effect unless the database in configured to use
  /// case sensitive like expressions.
  ///
  /// See https://www.sqlitetutorial.net/sqlite-like/ for more information on how
  /// to the like expression works.
  ComposableFilter contains(T value, {bool caseInsensitive = true}) {
    return $composableFilter(
        _buildExpression(_StringFilterTypes.contains, value, caseInsensitive));
  }

  /// Create a filter to check if the this text column starts with a substring
  ///
  /// Setting [caseInsensitive] to false will have no effect unless the database in configured to use
  /// case sensitive like expressions.
  ///
  /// See https://www.sqlitetutorial.net/sqlite-like/ for more information on how
  /// to the like expression works.
  ComposableFilter startsWith(T value, {bool caseInsensitive = true}) {
    return $composableFilter(_buildExpression(
        _StringFilterTypes.startsWith, value, caseInsensitive));
  }

  /// Create a filter to check if the this text column ends with a substring
  ///
  /// Setting [caseInsensitive] to false will have no effect unless the database in configured to use
  /// case sensitive like expressions.
  ///
  /// See https://www.sqlitetutorial.net/sqlite-like/ for more information on how
  /// to the like expression works.
  ComposableFilter endsWith(T value, {bool caseInsensitive = true}) {
    return $composableFilter(
        _buildExpression(_StringFilterTypes.endsWith, value, caseInsensitive));
  }
}

/// Built in filters for bool columns
extension BoolFilters on ColumnFilters<bool> {
  /// Create a filter to check if the column is bigger than a value
  ComposableFilter isTrue() => $composableFilter(column.equals(true));

  /// Create a filter to check if the column is small than a value
  ComposableFilter isFalse() => $composableFilter(column.equals(false));
}

/// Built in filters for int/double columns
extension NumFilters<T extends num> on ColumnFilters<T> {
  /// Create a filter to check if the column is bigger than a value
  ComposableFilter isBiggerThan(T value) =>
      $composableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is small than a value
  ComposableFilter isSmallerThan(T value) =>
      $composableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is bigger or equal to a value
  ComposableFilter isBiggerOrEqualTo(T value) =>
      $composableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is small or equal to a value
  ComposableFilter isSmallerOrEqualTo(T value) =>
      $composableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between two values
  /// This is done inclusively, so the column can be equal to the lower or higher value
  /// E.G isBetween(1, 3) will return true for 1, 2, and 3
  ComposableFilter isBetween(T lower, T higher) =>
      $composableFilter(column.isBetweenValues(lower, higher));
}

/// Built in filters for BigInt columns
extension BigIntFilters<T extends BigInt> on ColumnFilters<T> {
  /// Create a filter to check if the column is bigger than a value
  ComposableFilter isBiggerThan(T value) =>
      $composableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is small than a value
  ComposableFilter isSmallerThan(T value) =>
      $composableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is bigger or equal to a value
  ComposableFilter isBiggerOrEqualTo(T value) =>
      $composableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is small or equal to a value
  ComposableFilter isSmallerOrEqualTo(T value) =>
      $composableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between two values
  /// This is done inclusively, so the column can be equal to the lower or higher value
  /// E.G isBetween(1, 3) will return true for 1, 2, and 3
  ComposableFilter isBetween(T lower, T higher) =>
      $composableFilter(column.isBetweenValues(lower, higher));
}

/// Built in filters for DateTime columns
extension DateFilters<T extends DateTime> on ColumnFilters<T> {
  /// Create a filter to check if the column is after a [DateTime]
  ComposableFilter isAfter(T value) =>
      $composableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is before a [DateTime]
  ComposableFilter isBefore(T value) =>
      $composableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is on or after a [DateTime]
  ComposableFilter isAfterOrOn(T value) =>
      $composableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is before or on a [DateTime]
  ComposableFilter isBeforeOrOn(T value) =>
      $composableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between 2 [DateTime]s
  /// This is done inclusively, so the column can be equal to the lower or higher value
  /// E.G isBetween(1, 3) will return true for 1, 2, and 3
  ComposableFilter isBetween(T lower, T higher) =>
      $composableFilter(column.isBetweenValues(lower, higher));
}

/// Defines a class which is used to wrap a column with a type converter to only expose filter functions
// [CustomType] is the type that the user has defined in their type converter
// [CustomTypeNonNullable] is the type that the user has defined in their type converter, but is non-nullable
class ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable,
    T extends Object> {
  /// Similar to [ColumnFilters] but for columns with type converters\
  const ColumnWithTypeConverterFilters(this.column,
      [this.inverted = false, this._joinBuilder]);

  /// If true, all filters will be inverted
  final bool inverted;

  /// Column that this [ColumnWithTypeConverterFilters] wraps
  final GeneratedColumnWithTypeConverter<CustomType, T> column;

  /// If this column is part of a join, this will hold the join builder
  final JoinBuilder? _joinBuilder;

  /// Returns a copy of these column filters where all the filters are inverted
  /// ```dart
  /// myColumn.not.equals(5); // All columns that aren't null and have a value that is not equal to 5
  /// ```
  /// Keep in mind that while using inverted filters, null is never returned.
  ///
  /// If you would like to include them, use the [isNull] filter as well
  /// ```dart
  /// myColumn.not.equals(5) | myColumn.isNull(); // All columns that are null OR have a value that is not equal to 5
  /// ```
  ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable, T>
      get not =>
          ColumnWithTypeConverterFilters(column, !inverted, _joinBuilder);

  /// Create a composable filter from an expression, this is used to create
  /// lower level filters that can be composed together.
  ComposableFilter $composableFilter(Expression<bool> expression) {
    return ComposableFilter._(inverted ? expression.not() : expression,
        _joinBuilder != null ? {_joinBuilder} : {});
  }

  /// Create a filter that checks if the column is null.
  ComposableFilter isNull() => $composableFilter(column.isNull());

  /// Get the actual value from the custom type
  T _customTypeToSql(CustomTypeNonNullable value) {
    assert(value != null,
        'The filter value cannot be null. This is likely a bug in the generated code. Please report this issue.');
    final mappedValue = column.converter.toSql(value as CustomType);

    if (mappedValue == null) {
      throw ArgumentError(
          'The TypeConverter for this column returned null when converting the type to sql.'
          'Ensure that your TypeConverter never returns null when provided a non-null value.');
    }
    return mappedValue;
  }

  /// Create a filter that checks if the column equals a value.
  ComposableFilter equals(CustomTypeNonNullable value) {
    return $composableFilter(column.equals(_customTypeToSql(value)));
  }

  /// Shortcut for [equals]
  ComposableFilter call(CustomTypeNonNullable value) => equals(value);

  /// Create a filter that checks if the column is in a list of values.
  ComposableFilter isIn(Iterable<CustomTypeNonNullable> values) =>
      $composableFilter(column.isIn(values.map(_customTypeToSql).toList()));
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
  late final Expression<bool> expression;

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
}

/// The class that orchestrates the composition of filtering
class FilterComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  /// Create a new filter composer with a column
  ColumnFilters<C> $columnFilter<C extends Object>(GeneratedColumn<C> column) {
    // Get a copy of the column with the aliased name, if it's part of a join
    // otherwise, it's just a copy of the column
    final aliasedColumn = _columnWithAlias(column);

    // Doing a join to filter on a column that is part of the actual join
    // is a waste of time, do the filter on the actual column
    if ($joinBuilder != null &&
        $joinBuilder!.referencedColumn == aliasedColumn) {
      return ColumnFilters(
          $joinBuilder!.currentColumn as GeneratedColumn<C>, false, null);
    }

    return ColumnFilters(aliasedColumn, false, $joinBuilder);
  }

  /// Create a new filter composer with a column
  ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable, C>
      $columnFilterWithTypeConverter<CustomType, CustomTypeNonNullable,
              C extends Object>(
          GeneratedColumnWithTypeConverter<CustomType, C> column) {
    // Get a copy of the column with the aliased name, if it's part of a join
    // otherwise, it's just a copy of the column
    GeneratedColumnWithTypeConverter<CustomType, C> aliasedColumn =
        _columnWithAlias(column);
    return ColumnWithTypeConverterFilters(aliasedColumn, false, $joinBuilder);
  }

  /// Create a filter composer with an empty state
  FilterComposer(super.$db, super.$table, {super.$joinBuilder});
}
