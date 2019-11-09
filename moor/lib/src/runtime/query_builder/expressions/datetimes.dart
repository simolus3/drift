part of '../query_builder.dart';

/// Extracts the (UTC) year from the given expression that resolves
/// to a datetime.
@Deprecated('Use date.year instead')
Expression<int, IntType> year(Expression<DateTime, DateTimeType> date) =>
    date.year;

/// Extracts the (UTC) month from the given expression that resolves
/// to a datetime.
@Deprecated('Use date.month instead')
Expression<int, IntType> month(Expression<DateTime, DateTimeType> date) =>
    date.month;

/// Extracts the (UTC) day from the given expression that resolves
/// to a datetime.
@Deprecated('Use date.day instead')
Expression<int, IntType> day(Expression<DateTime, DateTimeType> date) =>
    date.day;

/// Extracts the (UTC) hour from the given expression that resolves
/// to a datetime.
@Deprecated('Use date.hour instead')
Expression<int, IntType> hour(Expression<DateTime, DateTimeType> date) =>
    date.hour;

/// Extracts the (UTC) minute from the given expression that resolves
/// to a datetime.
@Deprecated('Use date.minute instead')
Expression<int, IntType> minute(Expression<DateTime, DateTimeType> date) =>
    date.minute;

/// Extracts the (UTC) second from the given expression that resolves
/// to a datetime.
@Deprecated('Use date.second instead')
Expression<int, IntType> second(Expression<DateTime, DateTimeType> date) =>
    date.second;

/// A sql expression that evaluates to the current date represented as a unix
/// timestamp. The hour, minute and second fields will be set to 0.
const Expression<DateTime, DateTimeType> currentDate =
    _CustomDateTimeExpression("strftime('%s', CURRENT_DATE)");

/// A sql expression that evaluates to the current date and time, similar to
/// [DateTime.now]. Timestamps are stored with a second accuracy.
const Expression<DateTime, DateTimeType> currentDateAndTime =
    _CustomDateTimeExpression("strftime('%s', CURRENT_TIMESTAMP)");

class _CustomDateTimeExpression
    extends CustomExpression<DateTime, DateTimeType> {
  @override
  final Precedence precedence = Precedence.primary;

  const _CustomDateTimeExpression(String content) : super(content);
}

/// Provides expressions to extract information from date time values, or to
/// calculate the difference between datetimes.
extension DateTimeExpressions on Expression<DateTime, DateTimeType> {
  /// Extracts the (UTC) year from `this` datetime expression.
  Expression<int, IntType> get year =>
      _StrftimeSingleFieldExpression('%Y', this);

  /// Extracts the (UTC) month from `this` datetime expression.
  Expression<int, IntType> get month =>
      _StrftimeSingleFieldExpression('%m', this);

  /// Extracts the (UTC) day from `this` datetime expression.
  Expression<int, IntType> get day =>
      _StrftimeSingleFieldExpression('%d', this);

  /// Extracts the (UTC) hour from `this` datetime expression.
  Expression<int, IntType> get hour =>
      _StrftimeSingleFieldExpression('%H', this);

  /// Extracts the (UTC) minute from `this` datetime expression.
  Expression<int, IntType> get minute =>
      _StrftimeSingleFieldExpression('%M', this);

  /// Extracts the (UTC) second from `this` datetime expression.
  Expression<int, IntType> get second =>
      _StrftimeSingleFieldExpression('%S', this);

  /// Returns an expression containing the amount of seconds from the unix
  /// epoch (January 1st, 1970) to `this` datetime expression. The datetime is
  /// assumed to be in utc.
  // for moor, date times are just unix timestamps, so we don't need to rewrite
  // anything when converting
  Expression<int, IntType> get secondsSinceEpoch => dartCast();
}

/// Expression that extracts components out of a date time by using the builtin
/// sqlite function "strftime" and casting the result to an integer.
class _StrftimeSingleFieldExpression extends Expression<int, IntType> {
  final String format;
  final Expression<DateTime, DateTimeType> date;

  _StrftimeSingleFieldExpression(this.format, this.date);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('CAST(strftime("$format", ');
    date.writeInto(context);
    context.buffer.write(', "unixepoch") AS INTEGER)');
  }
}
