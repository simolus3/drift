import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';

Expression<int, IntType> year(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%Y', date);
Expression<int, IntType> month(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%m', date);
Expression<int, IntType> day(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%d', date);
Expression<int, IntType> hour(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%H', date);
Expression<int, IntType> minute(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%M', date);
Expression<int, IntType> second(Expression<DateTime, DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%S', date);

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
