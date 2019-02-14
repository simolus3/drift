import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';

Expression<IntType> year(Expression<DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%Y', date);
Expression<IntType> month(Expression<DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%m', date);
Expression<IntType> day(Expression<DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%d', date);
Expression<IntType> hour(Expression<DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%H', date);
Expression<IntType> minute(Expression<DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%M', date);
Expression<IntType> second(Expression<DateTimeType> date) =>
    _StrftimeSingleFieldExpression('%S', date);

/// Expression that extracts components out of a date time by using the builtin
/// sqlite function "strftime" and casting the result to an integer.
class _StrftimeSingleFieldExpression extends Expression<IntType> {
  final String format;
  final Expression<DateTimeType> date;

  _StrftimeSingleFieldExpression(this.format, this.date);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('CAST(strftime("$format", ');
    date.writeInto(context);
    context.buffer.write(', "unixepoch") AS INTEGER)');
  }
}
