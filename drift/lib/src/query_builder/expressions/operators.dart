import 'package:drift/src/query_builder/dialect.dart';

import 'package:drift/src/query_builder/types.dart';

import '../compiler.dart';
import 'expression.dart';

/// An expression of the form `<left> <operator> <right>`.
final class BinaryExpression<T extends Object> extends Expression<T> {
  /// The expression on the left-hand side of the [operator].
  final Expression left;

  /// The expression on the right-hand side of the [operator].
  final Expression right;

  /// The operator combining [left] and [right].
  final BinaryOperator operator;

  final SqlType<T> Function(DriftDialect)? _resolveType;

  /// Creates a binary expression by combining [left] and [right] with an
  /// [operator].
  const BinaryExpression(this.left, this.operator, this.right,
      {SqlType<T> Function(DriftDialect)? resolveType})
      : _resolveType = resolveType;

  @override
  Precedence get precedence => operator.precedence;

  @override
  SqlType<T> resolveType(DriftDialect dialect) {
    return _resolveType?.call(dialect) ?? dialect.resolveType<T>();
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addBinaryExpression(this);
  }
}

/// Binary operators supported by drift.
enum BinaryOperator implements SqlComponent {
  /// An `OR` expression in SQL.
  or(Precedence.or),

  /// An `AND` expression in SQL.
  and(Precedence.and);

  /// The [Precedence] associated with this binary operator.
  final Precedence precedence;

  const BinaryOperator(this.precedence);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addBinaryOperator(this);
  }
}

/// An expression of the form `<operator> <operand>` or `<operand> <operator>`.
final class UnaryExpression<T extends Object> extends Expression<T> {
  /// The operator applied to [operand].
  final UnaryOperator operator;

  /// The inner expression on which the [operator] is applied to.
  final Expression operand;

  final SqlType<T> Function(DriftDialect)? _resolveType;

  /// Create a unary expression from the [operator] and the [operand].
  const UnaryExpression(this.operator, this.operand,
      {SqlType<T> Function(DriftDialect)? resolveType})
      : _resolveType = resolveType;

  @override
  int get hashCode => Object.hash(operator, operand);

  @override
  Precedence get precedence => operator.precedence;

  @override
  bool operator ==(Object other) {
    return other is UnaryExpression &&
        other.operator == operator &&
        other.operand == operand;
  }

  @override
  SqlType<T> resolveType(DriftDialect dialect) {
    return _resolveType?.call(dialect) ?? dialect.resolveType<T>();
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addUnaryExpression(this);
  }
}

/// Unary SQL operators supported by drift.
enum UnaryOperator implements SqlComponent {
  /// A `NOT` operation in SQL.
  not(Precedence.not, true),

  /// A bitwise not operation in SQL.
  bitwiseNot(Precedence.unary, true),

  /// A unary minus in SQL.
  minus(Precedence.unary, true);

  /// The [Precedence] associated with this binary operator.
  final Precedence precedence;

  /// Whether this operator appears before (true) or after (false) the
  /// expression it is applied to in SQL.
  final bool isPrefix;

  const UnaryOperator(this.precedence, this.isPrefix);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addUnaryOperator(this);
  }
}
