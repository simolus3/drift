part of '../query_builder.dart';

/// A sql expression that evaluates to the current date represented as a unix
/// timestamp. The hour, minute and second fields will be set to 0.
const Expression<DateTime> currentDate =
    _CustomDateTimeExpression("strftime('%s', CURRENT_DATE)");

/// A sql expression that evaluates to the current date and time, similar to
/// [DateTime.now]. Timestamps are stored with a second accuracy.
const Expression<DateTime> currentDateAndTime =
    _CustomDateTimeExpression("strftime('%s', CURRENT_TIMESTAMP)");

class _CustomDateTimeExpression extends CustomExpression<DateTime> {
  @override
  Precedence get precedence => Precedence.primary;

  const _CustomDateTimeExpression(String content) : super(content);
}

/// Provides expressions to extract information from date time values, or to
/// calculate the difference between datetimes.
extension DateTimeExpressions on Expression<DateTime> {
  /// Extracts the (UTC) year from `this` datetime expression.
  Expression<int> get year => _StrftimeSingleFieldExpression('%Y', this);

  /// Extracts the (UTC) month from `this` datetime expression.
  Expression<int> get month => _StrftimeSingleFieldExpression('%m', this);

  /// Extracts the (UTC) day from `this` datetime expression.
  Expression<int> get day => _StrftimeSingleFieldExpression('%d', this);

  /// Extracts the (UTC) hour from `this` datetime expression.
  Expression<int> get hour => _StrftimeSingleFieldExpression('%H', this);

  /// Extracts the (UTC) minute from `this` datetime expression.
  Expression<int> get minute => _StrftimeSingleFieldExpression('%M', this);

  /// Extracts the (UTC) second from `this` datetime expression.
  Expression<int> get second => _StrftimeSingleFieldExpression('%S', this);

  /// Formats this datetime in the format `year-month-day`.
  Expression<String> get date {
    return FunctionCallExpression(
      'DATE',
      [this, const Constant<String>('unixepoch')],
    );
  }

  /// Returns an expression containing the amount of seconds from the unix
  /// epoch (January 1st, 1970) to `this` datetime expression. The datetime is
  /// assumed to be in utc.
  // for moor, date times are just unix timestamps, so we don't need to rewrite
  // anything when converting
  Expression<int> get secondsSinceEpoch => dartCast();

  /// Adds [duration] from this date.
  Expression<DateTime> operator +(Duration duration) {
    return _BaseInfixOperator(this, '+', Variable<int>(duration.inSeconds),
        precedence: Precedence.plusMinus);
  }

  /// Subtracts [duration] from this date.
  Expression<DateTime> operator -(Duration duration) {
    return _BaseInfixOperator(this, '-', Variable<int>(duration.inSeconds),
        precedence: Precedence.plusMinus);
  }
}

/// Expression that extracts components out of a date time by using the builtin
/// sqlite function "strftime" and casting the result to an integer.
class _StrftimeSingleFieldExpression extends Expression<int> {
  final String format;
  final Expression<DateTime> date;

  _StrftimeSingleFieldExpression(this.format, this.date);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("CAST(strftime('$format', ");
    date.writeInto(context);
    context.buffer.write(", 'unixepoch') AS INTEGER)");
  }

  @override
  int get hashCode => $mrjf($mrjc(format.hashCode, date.hashCode));

  @override
  bool operator ==(dynamic other) {
    return other is _StrftimeSingleFieldExpression &&
        other.format == format &&
        other.date == date;
  }
}
