part of '../query_builder.dart';

/// A custom expression that can appear in a sql statement.
/// The [CustomExpression.content] will be written into the query without any
/// modification.
///
/// See also:
///  - [currentDate] and [currentDateAndTime], which use a [CustomExpression]
///  internally.
class CustomExpression<D, S extends SqlType<D>> extends Expression<D, S> {
  /// The SQL of this expression
  final String content;

  /// Constructs a custom expression by providing the raw sql [content].
  const CustomExpression(this.content);

  @override
  void writeInto(GenerationContext context) => context.buffer.write(content);
}
