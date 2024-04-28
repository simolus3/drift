// ignore_for_file: unnecessary_this

part of 'manager.dart';

/// Base class for all column filters
abstract class _BaseColumnFilters<T extends Object> {
  const _BaseColumnFilters(this.column,
      {this.inverted = false,
      this.joinBuilders = const {},
      this.groupByBuilders = const []});

  /// Column that this [ColumnFilters] wraps
  final Expression<T> column;

  /// If true, all filters will be inverted
  final bool inverted;

  /// If this column is part of a join, this will hold the join builder
  /// that is used to create the join
  ///
  /// ```dart
  /// todos.filter((f) => f.category.name.equals('important'))
  /// ```
  /// In the above example, the [FilterComposer]  returned from `f.category`
  /// will have a join builder on it that is used to create the join between
  /// the `categories` and `todos` table. This join builder is passed to the
  /// `f.category.name` filter to ensure that the filter is applied to the correct
  /// table.
  ///
  /// There are instances where the join builder is eventually discarded, such as when
  /// the filter is applied to the foreign key column itself (e.g  a filter on `f.category.id` will
  /// not use the join, it will apply the filter to `f.categoryId` instead).
  final Set<JoinBuilder> joinBuilders;

  /// When filtering on reverse relations, we will find ourselves using
  /// aggregate functions. This list will hold the group by builders that
  /// are used to filter on the aggregates.
  ///
  /// When this column filter is used to filter on an aggregate function, the
  /// last group by builder will be a [TempGroupByBuilder].
  ///
  final List<BaseGroupByBuilder> groupByBuilders;

  /// This helper method is used internally to create a new [ComposableFilter]s
  /// that respects the inverted state of the current filter
  ComposableFilter $composableFilter(Expression<bool>? expression) {
    // If there are groupByBuilders and the last one is a TempGroupByBuilder
    // then this filter is being used to filter on an aggregate function
    List<BaseGroupByBuilder> groupByBuilders = this.groupByBuilders;

    if (groupByBuilders.isNotEmpty &&
        groupByBuilders.last is TempGroupByBuilder) {
      // Set the having clause on the last group by builder
      final groupByBuilderWithHaving =
          (groupByBuilders.last as TempGroupByBuilder).withHaving(expression);

      // Return a new ComposableFilter with the having clause set
      return ComposableFilter._(null, joinBuilders, [
        ...groupByBuilders.sublist(0, groupByBuilders.length - 1)
            as List<GroupByBuilder>,
        groupByBuilderWithHaving
      ]);
    }

    return ComposableFilter._(inverted ? expression?.not() : expression,
        joinBuilders, groupByBuilders as List<GroupByBuilder>);
  }

  /// Create a filter that checks if the column is null.
  ComposableFilter isNull() => $composableFilter(column.isNull());

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
@internal
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
  ColumnFilters(super.column,
      {super.inverted = false, super.joinBuilders, super.groupByBuilders});

  @override
  ColumnFilters<T> get not => ColumnFilters(column,
      inverted: !inverted,
      joinBuilders: joinBuilders,
      groupByBuilders: groupByBuilders);

  /// Create a filter that checks if the column equals a value.
  ComposableFilter equals(T value) => $composableFilter(column.equals(value));

  /// Shortcut for [equals]
  ComposableFilter call(T value) => equals(value);

  /// Create a filter that checks if the column is in a list of values.
  ComposableFilter isIn(Iterable<T> values) =>
      $composableFilter(column.isIn(values));
}

/// Built in filters for columns that have a type converter
@internal
class ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable,
    T extends Object> extends _BaseColumnFilters<T> {
  /// This class is a wrapper on top of the generated column class
  /// for columns that have a type converter
  ///
  /// See [ColumnFilters] for more information on how to use this class
  ColumnWithTypeConverterFilters(super.column,
      {super.inverted = false, super.joinBuilders, super.groupByBuilders});

  @override
  ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable, T>
      get not => ColumnWithTypeConverterFilters(column,
          inverted: !inverted,
          joinBuilders: joinBuilders,
          groupByBuilders: groupByBuilders);

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
  ComposableFilter equals(CustomTypeNonNullable value) {
    return $composableFilter(column.equals(_customTypeToSql(value)));
  }

  /// Shortcut for [equals]
  ComposableFilter call(CustomTypeNonNullable value) => equals(value);

  /// Create a filter that checks if the column is in a list of values.
  ComposableFilter isIn(Iterable<CustomTypeNonNullable> values) =>
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

enum _ExpressionOpperator { and, or }

/// This class is used to compose filters together
///
/// This class contains all the information that will
/// be used to create a where expression for the [TableManagerState]
///
/// See [Queryset] for more information on how joins/group bys are stored
@internal
class ComposableFilter extends Queryset {
  @override
  final Set<JoinBuilder> joinBuilders;

  @override
  final List<GroupByBuilder> groupByBuilders;

  /// The expression that will be applied to the query
  Expression<bool>? expression;

  /// Create a new [ComposableFilter] for a column with joins
  ComposableFilter._(this.expression, this.joinBuilders, this.groupByBuilders);

  /// Combine two filters with an AND
  ComposableFilter operator &(ComposableFilter other) =>
      _combineFilter(_ExpressionOpperator.and, other);

  /// Combine two filters with an OR
  ComposableFilter operator |(ComposableFilter other) =>
      _combineFilter(_ExpressionOpperator.or, other);

  /// A helper function to combine two filters
  ComposableFilter _combineFilter(
      _ExpressionOpperator opperator, ComposableFilter otherFilter) {
    final combinedExpression = switch ((expression, otherFilter.expression)) {
      (null, null) => null,
      (null, var expression) => expression,
      (var expression, null) => expression,
      (_, _) => switch (opperator) {
          _ExpressionOpperator.and => expression! & otherFilter.expression!,
          _ExpressionOpperator.or => expression! | otherFilter.expression!,
        },
    };
    return ComposableFilter._(
      combinedExpression,
      joinBuilders.union(otherFilter.joinBuilders),
      [...groupByBuilders, ...otherFilter.groupByBuilders],
    );
  }
}

/// The class that orchestrates the composition of filtering
@internal
class FilterComposer<DB extends GeneratedDatabase, T extends Table>
    extends Composer<DB, T> {
  /// The internal function used to create column filters
  /// that respect the current join builder.
  ///
  /// Joins that are unnecessary are not created, and the filter is applied to the correct column
  /// E.G `todos.filter((f) => f.category.id.equals(5))` will apply the filter `category` field in the `todos` table
  /// instead of creating a join to the `categories` table.
  ColumnFilters<C> $columnFilter<C extends Object>(GeneratedColumn<C> column) {
    // Get a copy of the column with the aliased name, if it's part of a join
    // otherwise, it's just a copy of the column
    final aliasedColumn = _columnWithAlias(column);

    // Doing a join to filter on a column that is part of the actual join
    // is a waste of time, do the filter on the actual column
    if ($joinBuilder != null &&
        $joinBuilder!.referencedColumn == aliasedColumn) {
      return ColumnFilters($joinBuilder!.currentColumn as GeneratedColumn<C>);
    }

    return ColumnFilters(aliasedColumn,
        joinBuilders: $joinBuilder != null ? {$joinBuilder!} : {});
  }

  /// The internal function used to create column filters
  /// that respect the current join builder for columns with type converters.
  ///
  /// See [$columnFilter] for more information on how to use this function
  ColumnWithTypeConverterFilters<CustomType, CustomTypeNonNullable, C>
      $columnFilterWithTypeConverter<CustomType, CustomTypeNonNullable,
              C extends Object>(
          GeneratedColumnWithTypeConverter<CustomType, C> column) {
    // Get a copy of the column with the aliased name, if it's part of a join
    // otherwise, it's just a copy of the column
    GeneratedColumnWithTypeConverter<CustomType, C> aliasedColumn =
        _columnWithAlias(column);
    return ColumnWithTypeConverterFilters(aliasedColumn,
        joinBuilders: $joinBuilder != null ? {$joinBuilder!} : {});
  }

  /// A filter that includes all rows
  ComposableFilter all() =>
      ComposableFilter._(null, $joinBuilder != null ? {$joinBuilder!} : {}, []);

  /// A filter composer will be generated for each table.
  /// Each field on the table will return a [ColumnFilters] object
  /// ```dart
  /// todos.filter((f) => f.name.equals('Bob'));
  /// ```
  /// In the above example, `f` is a [FilterComposer] object, and `f.name` returns a [ColumnFilters] object.
  FilterComposer(super.$db, super.$table, {super.$joinBuilder});
}
