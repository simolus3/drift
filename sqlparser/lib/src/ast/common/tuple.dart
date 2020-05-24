part of '../ast.dart';

/// A tuple of values, denotes in brackets. `(<expr>, ..., <expr>)`.
///
/// In sqlite, this is also called a "row value".
class Tuple extends Expression {
  /// The expressions appearing in this tuple.
  final List<Expression> expressions;

  /// Whether this tuple is used as an expression, e.g. a [row value][r v].
  ///
  /// Other tuples might appear in `VALUES` clauses.
  ///
  /// [r v]: https://www.sqlite.org/rowvalue.html
  final bool usedAsRowValue;

  Tuple({@required this.expressions, this.usedAsRowValue = false});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitTuple(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    transformer.transformChildren(expressions, this, arg);
  }

  @override
  List<Expression> get childNodes => expressions;

  @override
  bool contentEquals(Tuple other) => true;
}
