part of '../query_builder.dart';

/// A where clause in a select, update or delete statement.
class Where extends Component {
  /// The expression that determines whether a given row should be included in
  /// the result.
  final Expression<bool, BoolType> predicate;

  /// Construct a [Where] clause from its [predicate].
  Where(this.predicate);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('WHERE ');
    predicate.writeInto(context);
  }

  @override
  int get hashCode => predicate.hashCode * 7;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        other is Where && other.predicate == predicate;
  }
}
