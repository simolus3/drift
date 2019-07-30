import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';

/// A custom expression that can appear in a sql statement.
/// The [CustomExpression.content] will be written into the query without any
/// modification.
///
/// See also:
///  - [currentDate] and [currentDateAndTime], which use a [CustomExpression]
///  internally.
class CustomExpression<D, S extends SqlType<D>> extends Expression<D, S> {
  final String content;

  const CustomExpression(this.content);

  @override
  void writeInto(GenerationContext context) => context.buffer.write(content);
}
