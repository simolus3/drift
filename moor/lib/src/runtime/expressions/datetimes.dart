import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/custom.dart';
import 'package:moor/src/runtime/expressions/expression.dart';

/// Extracts the (UTC) year from the given expression that resolves
/// to a datetime.
Expression<int, IntType> year(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%Y', date);

/// Extracts the (UTC) month from the given expression that resolves
/// to a datetime.
Expression<int, IntType> month(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%m', date);

/// Extracts the (UTC) day from the given expression that resolves
/// to a datetime.
Expression<int, IntType> day(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%d', date);

/// Extracts the (UTC) hour from the given expression that resolves
/// to a datetime.
Expression<int, IntType> hour(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%H', date);

/// Extracts the (UTC) minute from the given expression that resolves
/// to a datetime.
Expression<int, IntType> minute(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%M', date);

/// Extracts the (UTC) second from the given expression that resolves
/// to a datetime.
Expression<int, IntType> second(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%S', date);

/// A sql expression that evaluates to the current date represented as a unix
/// timestamp. The hour, minute and second fields will be set to 0.
const DateTimeExpression currentDate =
    _CustomDateTimeExpression("strftime('%s', CURRENT_DATE)");

/// A sql expression that evaluates to the current date and time, similar to
/// [DateTime.now]. Timestamps are stored with a second accuracy.
const DateTimeExpression currentDateAndTime =
    _CustomDateTimeExpression("strftime('%s', CURRENT_TIMESTAMP)");

class _CustomDateTimeExpression extends CustomExpression<DateTime, DateTimeType>
    with ComparableExpr
    implements DateTimeExpression {
  const _CustomDateTimeExpression(String content) : super(content);
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
