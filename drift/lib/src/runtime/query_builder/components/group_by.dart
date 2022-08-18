part of '../query_builder.dart';

/// A "group by" clause in sql.
class GroupBy extends Component {
  /// The expressions to group by.
  final List<Expression> groupBy;

  /// Optional, a having clause to exclude some groups.
  final Expression<bool>? having;

  GroupBy._(this.groupBy, this.having);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('GROUP BY ');
    _writeCommaSeparated(context, groupBy);

    if (having != null) {
      context.buffer.write(' HAVING ');
      having!.writeInto(context);
    }
  }
}
