part of '../query_builder.dart';

/// A custom expression that can appear in a sql statement.
/// The [CustomExpression.content] will be written into the query without any
/// modification.
///
/// See also:
///  - [currentDate] and [currentDateAndTime], which use a [CustomExpression]
///  internally.
class CustomExpression<D extends Object> extends Expression<D> {
  /// The SQL of this expression
  final String content;

  final Map<SqlDialect, String>? _dialectSpecificContent;

  /// Additional tables that this expression is watching.
  ///
  /// When this expression is used in a stream query, the stream will update
  /// when any table in [watchedTables] changes.
  /// Usually, expressions don't introduce new tables to watch. This field is
  /// mainly used for subqueries used as expressions.
  final Iterable<TableInfo> watchedTables;

  @override
  final Precedence precedence;

  /// Constructs a custom expression by providing the raw sql [content].
  const CustomExpression(this.content,
      {this.watchedTables = const [], this.precedence = Precedence.unknown})
      : _dialectSpecificContent = null;

  /// Constructs a custom expression providing the raw SQL in [content] depending
  /// on the SQL dialect when this expression is built.
  const CustomExpression.dialectSpecific(Map<SqlDialect, String> content,
      {this.watchedTables = const [], this.precedence = Precedence.unknown})
      : _dialectSpecificContent = content,
        content = '';

  @override
  void writeInto(GenerationContext context) {
    final dialectSpecific = _dialectSpecificContent;

    if (dialectSpecific != null) {
      final dialect = context.dialect;
      context.buffer.write(dialectSpecific[dialect]);
    } else {
      context.buffer.write(content);
    }

    context.watchedTables.addAll(watchedTables);
  }

  @override
  int get hashCode => content.hashCode * 3;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        // ignore: test_types_in_equals
        (other as CustomExpression).content == content;
  }
}
