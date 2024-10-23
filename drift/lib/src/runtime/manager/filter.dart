part of 'manager.dart';

/// Base class for all column filters
abstract class _BaseColumnFilters<T extends Object> {
  const _BaseColumnFilters(this.column, {this.inverted = false});

  /// Column that this [ColumnFilters] wraps
  final Expression<T> column;

  /// If true, all filters will be inverted
  final bool inverted;

  /// This helper method is used internally to create a new [Expression<bool>]s
  /// that respects the inverted state of the current filter
  Expression<bool> $composableFilter(Expression<bool> expression) {
    return inverted ? expression.not() : expression;
  }

  /// Create a filter that checks if the column is null.
  Expression<bool> isNull() => $composableFilter(column.isNull());

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
  _BaseColumnFilters get not;
}

/// Built in filters for all columns
class ColumnFilters<T extends Object> extends _BaseColumnFilters<T> {
  /// This class is a wrapper on top of the generated column class
  ///
  /// It's used to expose filter functions for a column type
  ///
  /// ```dart
  /// todos.filter((f) => f.name('important'))
  /// ```
  /// In the above example, f.name returns a [ColumnFilters] object, which
  /// contains methods for creating filters on the `name` column.
  /// ```
  /// {@macro manager_internal_use_only}
  ColumnFilters(super.column, {super.inverted = false});

  @override
  ColumnFilters<T> get not => ColumnFilters(column, inverted: !inverted);

  /// Create a filter that checks if the column equals a value.
  Expression<bool> equals(T? value) =>
      $composableFilter(column.equalsNullable(value));

  /// Shortcut for [equals]
  Expression<bool> call(T? value) => equals(value);

  /// Create a filter that checks if the column is in a list of values.
  Expression<bool> isIn(Iterable<T> values) =>
      $composableFilter(column.isIn(values));
}

/// Built in filters for columns that have a type converter
class ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable,
    T extends Object> extends _BaseColumnFilters<T> {
  /// This class is a wrapper on top of the generated column class
  /// for columns that have a type converter
  ///
  /// See [ColumnFilters] for more information on how to use this class
  ///
  /// {@macro manager_internal_use_only}
  ColumnWithTypeConverterFilters(super.column, {super.inverted = false});

  @override
  ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable, T>
      get not => ColumnWithTypeConverterFilters(column, inverted: !inverted);

  GeneratedColumnWithTypeConverter<CustomType, T> get _typedColumn =>
      column as GeneratedColumnWithTypeConverter<CustomType, T>;

  /// Get the actual value from the custom type
  T _customTypeToSql(CustomTypeNonNullable value) {
    assert(value != null,
        'The filter value cannot be null. This is likely a bug in the generated code. Please report this issue.');
    final mappedValue = _typedColumn.converter.toSql(value as CustomType);

    if (mappedValue == null) {
      throw ArgumentError(
          'The TypeConverter for this column returned null when converting the type to sql.'
          'Ensure that your TypeConverter never returns null when provided a non-null value.');
    }
    return mappedValue;
  }

  /// Create a filter that checks if the column equals a value.
  Expression<bool> equals(CustomTypeNonNullable value) {
    return $composableFilter(column.equals(_customTypeToSql(value)));
  }

  /// Shortcut for [equals]
  Expression<bool> call(CustomTypeNonNullable value) => equals(value);

  /// Create a filter that checks if the column is in a list of values.
  Expression<bool> isIn(Iterable<CustomTypeNonNullable> values) =>
      $composableFilter(column.isIn(values.map(_customTypeToSql).toList()));
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
  /// the database to be case sensitive wont be confused why their like expressions are case insensitive
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
  Expression<bool> contains(T value, {bool caseInsensitive = true}) {
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
  Expression<bool> startsWith(T value, {bool caseInsensitive = true}) {
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
  Expression<bool> endsWith(T value, {bool caseInsensitive = true}) {
    return $composableFilter(
        _buildExpression(_StringFilterTypes.endsWith, value, caseInsensitive));
  }
}

/// Built in filters for bool columns
extension BoolFilters on ColumnFilters<bool> {
  /// Create a filter to check if the column is bigger than a value
  Expression<bool> isTrue() => $composableFilter(column.equals(true));

  /// Create a filter to check if the column is small than a value
  Expression<bool> isFalse() => $composableFilter(column.equals(false));
}

/// Built in filters for int/double columns
extension NumFilters<T extends num> on ColumnFilters<T> {
  /// Create a filter to check if the column is bigger than a value
  Expression<bool> isBiggerThan(T value) =>
      $composableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is small than a value
  Expression<bool> isSmallerThan(T value) =>
      $composableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is bigger or equal to a value
  Expression<bool> isBiggerOrEqualTo(T value) =>
      $composableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is small or equal to a value
  Expression<bool> isSmallerOrEqualTo(T value) =>
      $composableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between two values
  /// This is done inclusively, so the column can be equal to the lower or higher value
  /// E.G isBetween(1, 3) will return true for 1, 2, and 3
  Expression<bool> isBetween(T lower, T higher) =>
      $composableFilter(column.isBetweenValues(lower, higher));
}

/// Built in filters for BigInt columns
extension BigIntFilters<T extends BigInt> on ColumnFilters<T> {
  /// Create a filter to check if the column is bigger than a value
  Expression<bool> isBiggerThan(T value) =>
      $composableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is small than a value
  Expression<bool> isSmallerThan(T value) =>
      $composableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is bigger or equal to a value
  Expression<bool> isBiggerOrEqualTo(T value) =>
      $composableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is small or equal to a value
  Expression<bool> isSmallerOrEqualTo(T value) =>
      $composableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between two values
  /// This is done inclusively, so the column can be equal to the lower or higher value
  /// E.G isBetween(1, 3) will return true for 1, 2, and 3
  Expression<bool> isBetween(T lower, T higher) =>
      $composableFilter(column.isBetweenValues(lower, higher));
}

/// Built in filters for DateTime columns
extension DateFilters<T extends DateTime> on ColumnFilters<T> {
  /// Create a filter to check if the column is after a [DateTime]
  Expression<bool> isAfter(T value) =>
      $composableFilter(column.isBiggerThanValue(value));

  /// Create a filter to check if the column is before a [DateTime]
  Expression<bool> isBefore(T value) =>
      $composableFilter(column.isSmallerThanValue(value));

  /// Create a filter to check if the column is on or after a [DateTime]
  Expression<bool> isAfterOrOn(T value) =>
      $composableFilter(column.isBiggerOrEqualValue(value));

  /// Create a filter to check if the column is before or on a [DateTime]
  Expression<bool> isBeforeOrOn(T value) =>
      $composableFilter(column.isSmallerOrEqualValue(value));

  /// Create a filter to check if the column is between 2 [DateTime]s
  /// This is done inclusively, so the column can be equal to the lower or higher value
  /// E.G isBetween(1, 3) will return true for 1, 2, and 3
  Expression<bool> isBetween(T lower, T higher) =>
      $composableFilter(column.isBetweenValues(lower, higher));
}

///  Enum of the possible boolean operators
enum _BooleanOperator {
  /// Combine the existing filters to the new filter with an AND
  and,

  /// Combine the existing filters to the new filter with an OR
  or;
}
