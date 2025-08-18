part of '../query_builder.dart';

/// Represents a window function expression in SQL.
///
/// Window functions perform calculations across a set of table rows that are somehow
/// related to the current row. This expression class allows you to construct window
/// function queries with partitioning, ordering, and frame specifications.
///
/// More information at [Window Functions](https://www.sqlite.org/windowfunctions.html) documentation.
class WindowFunctionExpression<T extends Object> extends Expression<T> {
  /// The aggregate or window function to apply (e.g., SUM, AVG).
  final Expression<T> function;

  /// The ordering terms that define how rows are sorted within each partition.
  /// Must not be empty as window functions require an ORDER BY clause.
  final List<OrderingTerm> orderBy;

  /// Optional list of expressions to partition the rows by.
  ///
  /// When specified, the window function calculations are performed separately
  /// for each distinct combination of the partition values.
  final List<Expression>? partitionBy;

  /// Optional frame boundary that defines which rows to include in the
  /// window calculations relative to the current row.
  ///
  /// If not specified, defaults to a RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
  ///
  /// Usage:
  ///
  /// ```dart
  /// // RANGE Boundary
  ///  boundary: FrameBoundary.range(),
  ///
  /// // ROWS Boundary
  ///  boundary: FrameBoundary.rows(),
  ///
  /// // GROUPS Boundary
  ///  boundary: GroupFrameBoundary(),
  /// ```
  final FrameBoundary boundary;

  /// Creates a new window function expression.
  ///
  /// Parameters:
  /// - [function]: The window or aggregate function to apply
  /// - [orderBy]: How to sort rows within each partition (required, must not be empty)
  /// - [partitionBy]: Optional expressions to partition rows by
  /// - [boundary]: Optional specification of which rows to include in calculations
  ///
  /// Throws [ArgumentError] if [orderBy] is empty.
  ///
  /// Note that Window Function is only available from sqlite 3.25.0, released on 2018-09-15.
  /// Most devices will use an older sqlite version.
  ///
  /// EXCLUDE clause, GROUPS frame types, window chaining, and
  /// support for `<expr> PRECEDING` and `<expr> FOLLOWING` boundaries in RANGE frames
  /// are only available from sqlite 3.28.0, released on 2019-04-16.
  ///
  /// More information at [Window Functions](https://www.sqlite.org/windowfunctions.html) documentation.
  ///
  /// # Basic Usage
  ///
  /// ```dart
  /// // Simple running total example
  /// final runningTotal = WindowFunctionExpression<double>(
  ///   items.price.sum(), // aggregate function
  ///   orderBy: [OrderingTerm.asc(items.date)],
  /// );
  ///
  /// // Use in a query
  /// final query = select(items).addColumns([runningTotal]);
  /// ```
  ///
  /// # Partitioning
  ///
  /// Partition data into groups before applying the window function:
  ///
  /// ```dart
  /// // Running total per category
  /// final runningTotalByCategory = WindowFunctionExpression<int>(
  ///   items.price.sum(),
  ///   orderBy: [OrderingTerm.asc(items.date)],
  ///   partitionBy: [items.categoryId],
  /// );
  /// ```
  ///
  /// # Frame Boundaries
  ///
  /// ## Rows Frame
  /// Operates on physical rows:
  ///
  /// ```dart
  /// // Moving average of previous 3 rows and current row
  /// final movingAverage = WindowFunctionExpression<double>(
  ///   items.price.avg(),
  ///   orderBy: [OrderingTerm.asc(items.date)],
  ///   boundary: FrameBoundary.rows(
  ///     start: -3, // 3 rows preceding
  ///     end: 0,    // current row
  ///   ),
  /// );
  /// ```
  ///
  /// ## Groups Frame
  /// Operates on groups of rows with same ORDER BY values:
  ///
  /// ```dart
  /// // Include current group and one group before
  /// final groupFrame = WindowFunctionExpression<int>(
  ///   items.quantity.sum(),
  ///   orderBy: [OrderingTerm.asc(items.category)],
  ///   boundary: FrameBoundary.groups(
  ///     start: null, // Unbounded preceding groups
  ///     end: 0,    // current group
  ///   ),
  /// );
  /// ```
  ///
  /// ## Range Frame
  /// Operates on value ranges (default):
  ///
  /// ```dart
  /// // Sum of items within price range of ±10 from current row
  /// final rangeFrame = WindowFunctionExpression<int>(
  ///   items.quantity.sum(),
  ///   orderBy: [OrderingTerm.asc(items.price)],
  ///   boundary: FrameBoundary.range(
  ///     start: -10, // 10 units less than current value
  ///     end: 10,    // 10 units more than current value
  ///   ),
  /// );
  /// ```
  ///
  WindowFunctionExpression(
    this.function, {
    required this.orderBy,
    this.partitionBy,
    this.boundary = const FrameBoundary.range(),
  }) {
    if (orderBy.isEmpty) {
      throw ArgumentError.value(
        orderBy,
        'orderBy',
        'Must not be empty',
      );
    }
  }

  @override
  void writeInto(GenerationContext context) {
    function.writeInto(context);
    context.buffer.write(' OVER (');
    if (partitionBy case final partitionBy? when partitionBy.isNotEmpty) {
      _PartitionBy(partitionBy).writeInto(context);
      context.writeWhitespace();
    }
    OrderBy(orderBy).writeInto(context);
    context.writeWhitespace();
    boundary.writeInto(context);
    context.buffer.write(')');
  }
}

/// A partition-by clause as part of a window function statement. The clause can consist
/// of multiple [Expression]s, with the first terms being primary partition and
/// the later terms will work as a nested partition for the previous partition and so on.
class _PartitionBy extends Component {
  /// The list of expressions to partition by.
  final List<Expression> expressions;

  /// Constructs a partition by clause by the [expressions].
  const _PartitionBy(this.expressions);

  @override
  void writeInto(GenerationContext context) {
    if (expressions.isEmpty) return;

    context.buffer.write('PARTITION BY ');
    _writeCommaSeparated(context, expressions);
  }
}

/// Specifies how to exclude rows from the window frame.
enum FrameExclude {
  /// No rows are excluded from the window frame.
  ///
  /// This is the default behavior
  noOthers._('NO OTHERS'),

  /// Excludes the current row from the window frame.
  currentRow._('CURRENT ROW'),

  /// Excludes the current row and its peers from the window frame.
  ///
  /// Peers are rows that are considered equivalent to the current row based on
  /// the window's ORDER BY clause.
  group._('GROUP'),

  /// Excludes the peers of the current row from the window frame, but keeps the current row.
  ///
  /// Only rows that have exactly the same values for the ORDER BY columns as the
  /// current row are excluded, while the current row itself remains in the frame.
  ties._('TIES');

  /// The string representation of the exclude clause.
  final String _exclude;

  const FrameExclude._(this._exclude);
}

/// Describes the type of frame for a window function.
enum _FrameType {
  /// A frame that considers a range of values for the provided boundary.
  ///
  /// `RANGE` frames operate based on the values in the `ORDER BY` clause,
  /// not row positions. It includes all rows that fall within the specified
  /// value range relative to the current row.
  ///
  /// If multiple rows have the same value in the `ORDER BY` column, they
  /// are all included in the frame.
  range._('RANGE'),

  /// A frame that considers a number of rows for the provided boundary.
  ///
  /// Each row is treated as a separate entity, and the frame is defined
  /// by a specific number of rows before or after the current row.
  rows._('ROWS'),

  /// A frame that considers a number of groups for the provided boundary.
  ///
  /// A group is a set of rows that share the same values for every term
  /// in the `ORDER BY` clause. The frame includes a specified number of
  /// groups before or after the current group.
  groups._('GROUPS');

  /// The string representation of the frame type.
  final String _type;

  const _FrameType._(this._type);
}

/// Base Class for Boundary in a window frame.
///
/// {@template drift_window_boundary}
/// If null, the boundary is unbounded.
///
/// Negative value indicates a preceding boundary
///
/// Positive value indicates a following boundary
///
/// Zero indicates the current row
///
/// {@endtemplate}
///
/// More information at [FrameBoundary](https://www.sqlite.org/windowfunctions.html#frame_boundaries) documentation.
final class FrameBoundary extends Component {
  /// The start of the frame boundary, relative to the current row.
  ///
  /// A value of [null] indicates that frame includes all prior rows, groups or range bounds.
  /// A value of 0 indicates that frame starts at the current row.
  ///
  /// A negative or positive value indicates that frame starts at the specified offset
  /// before or after the current row.
  final num? start;

  /// The end of the frame boundary, relative to the current row.
  ///
  /// A value of [null] indicates that frame includes all following rows, groups or range bounds.
  /// A value of 0 indicates that frame ends at the current row.
  ///
  /// A negative or positive value indicates that frame ends at the specified offset
  /// before or after the current row.
  final num? end;

  /// The type of frame for the boundary.
  final _FrameType _frameType;

  /// Specifies which rows to exclude from the frame
  ///
  /// If not specified, defaults to [FrameExclude.noOthers].
  ///
  /// Note that [exclude] is only available from sqlite 3.28.0, released on 2019-04-16.
  /// Most devices will use an older sqlite version.
  ///
  /// If you want to use [FrameExclude.noOthers] then keeping [exclude] as null will give you the same behaviour.
  final FrameExclude? exclude;

  const FrameBoundary._(
    this.start,
    this.end,
    this._frameType, {
    this.exclude,
  }) : assert(
          start == null || start <= 0 || (end == null || end > 0),
          'Invalid frame specification. A FOLLOWING start boundary must have an end boundary as FOLLOWING or UNBOUNDED.',
        );

  /// Constructs a ROWS frame with the given [start] and [end] boundaries.
  ///
  /// A ROWS frame operates on physical rows. The [start] and [end] parameter specifies how
  /// many rows before and/or after the current row should be included in the frame.
  ///
  /// {@macro drift_window_boundary}
  const FrameBoundary.rows({
    int? start,
    int? end = 0,
    FrameExclude? exclude,
  }) : this._(start, end, _FrameType.rows, exclude: exclude);

  /// Constructs a GROUPS frame with the given [start] and [end] boundaries.
  ///
  /// A GROUPS frame operates on groups of rows that share the same values in the
  /// ORDER BY columns. The [start] and [end] parameter specifies how many groups before
  /// and/or after the current row's group should be included.
  ///
  /// Note that GROUPS Frame Type is only available from sqlite 3.28.0, released on 2019-04-16.
  /// Most devices will use an older sqlite version.
  ///
  /// {@macro drift_window_boundary}
  const FrameBoundary.groups({
    int? start,
    int? end = 0,
    FrameExclude? exclude,
  }) : this._(start, end, _FrameType.groups, exclude: exclude);

  /// Constructs a RANGE boundary with the given [start] and [end].
  ///
  /// A RANGE frame operates on logical ranges of values based on the ORDER BY columns.
  /// The [start] and [end] parameter specifies the range of values to include relative to
  /// the current row's values.
  ///
  /// If multiple rows have the same value in the `ORDER BY` column, they
  /// are all included in the frame.
  ///
  /// {@macro drift_window_boundary}
  ///
  /// Note that passing value except 0 (CURRENT ROW) or null (UNBOUNDED) to [start] or [end] in RANGE Frame is only available from sqlite 3.28.0, released on 2019-04-16.
  /// Most devices will use an older sqlite version.
  ///
  /// 0 (CURRENT ROW) and null (UNBOUNDED) are supported from sqlite 3.25.0, released on 2018-09-15.
  const FrameBoundary.range({
    num? start,
    num? end = 0,
    FrameExclude? exclude,
  }) : this._(start, end, _FrameType.range, exclude: exclude);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(_frameType._type);
    context.buffer.write(' BETWEEN ');
    if (start case final start?) {
      _writeBoundary(context, start);
    } else {
      context.buffer.write('UNBOUNDED PRECEDING');
    }
    context.buffer.write(' AND ');
    if (end case final end?) {
      _writeBoundary(context, end);
    } else {
      context.buffer.write('UNBOUNDED FOLLOWING');
    }
    if (exclude case final exclude?) {
      context.buffer.write(' EXCLUDE ');
      context.buffer.write(exclude._exclude);
    }
  }

  void _writeBoundary(GenerationContext context, num exp) {
    if (exp == 0) {
      context.buffer.write('CURRENT ROW');
    } else if (exp < 0) {
      Constant(exp.abs()).writeInto(context);
      context.buffer.write(' PRECEDING');
    } else {
      Constant(exp.abs()).writeInto(context);
      context.buffer.write(' FOLLOWING');
    }
  }
}
