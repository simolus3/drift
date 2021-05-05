import '../../reader/tokenizer/token.dart';
import '../node.dart';
import '../statements/select.dart' show ResultColumn;
import '../visitor.dart';

/// A returning clause describes expressions to evaluate after an insert, an
/// update or a delete statement.
class Returning extends AstNode {
  /// The `RETURNING` token as found in the source.
  Token? returning;
  List<ResultColumn> columns;

  Returning(this.columns);

  @override
  List<ResultColumn> get childNodes => columns;

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitReturning(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    columns = transformer.transformChildren(columns, this, arg);
  }
}
