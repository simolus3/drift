import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'expression.dart';

/// An expression of the form `<left> <operator> <right>`.
final class BinaryExpression<T extends Object> extends Expression<T> {
  /// The expression on the left-hand side of the [operator].
  final Expression left;

  /// The expression on the right-hand side of the [operator].
  final Expression right;

  /// The operator combining [left] and [right].
  final BinaryOperator operator;

  final PhysicalSqlType<T> Function(DriftDialect)? _resolveType;

  /// Creates a binary expression by combining [left] and [right] with an
  /// [operator].
  const BinaryExpression(
    this.left,
    this.operator,
    this.right, {
    PhysicalSqlType<T> Function(DriftDialect)? resolveType,
  }) : _resolveType = resolveType;

  @override
  Precedence get precedence => operator.precedence;

  @override
  int get hashCode => Object.hash(left, operator, right);

  @override
  bool operator ==(Object other) {
    return other is BinaryExpression &&
        other.operator == operator &&
        other.left == left &&
        other.right == right;
  }

  @override
  PhysicalSqlType<T> resolveType(DriftDialect dialect) {
    return _resolveType?.call(dialect) ?? dialect.resolveType<T>();
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addBinaryExpression(this);
  }
}

/// Binary operators supported by drift.
enum BinaryOperator implements SqlComponent {
  /// A `->` operator in SQL.
  jsonExtractAsJson(Precedence.stringConcatenation, '->'),

  /// A `->>` operator in SQL.
  jsonExtractAsValue(Precedence.stringConcatenation, '->>'),

  /// A `||` operator in SQL.
  stringConcatenation(Precedence.stringConcatenation, '||'),

  /// A `*` operator in SQL.
  multiply(Precedence.mulDivide, '*'),

  /// A `/` operator in SQL.
  divide(Precedence.mulDivide, '/'),

  /// A `%` operator in SQL.
  modulo(Precedence.mulDivide, '%'),

  /// A `+` operator in SQL.
  plus(Precedence.plusMinus, '+'),

  /// A `-` operator in SQL.
  minus(Precedence.plusMinus, '-'),

  /// A `&` operator in SQL.
  bitwiseAnd(Precedence.bitwise, '&'),

  /// A `|` operator in SQL.
  bitwiseOr(Precedence.bitwise, '|'),

  /// A `<` operator in SQL.
  less(Precedence.comparison, '<'),

  /// A `<=` operator in SQL.
  lessOrEqual(Precedence.comparison, '<='),

  /// A `>` operator in SQL.
  greater(Precedence.comparison, '>'),

  /// A `>=` operator in SQL.
  greaterOrEqual(Precedence.comparison, '>='),

  /// A `=` operator in SQL.
  equals(Precedence.comparisonEq, '='),

  /// A `LIKE` operator in SQL.
  like(Precedence.comparison, 'LIKE'),

  /// A `LIKE` operator in SQL.
  regexp(Precedence.comparison, 'REGEXP'),

  /// An `IS` operator in SQL.
  $is(Precedence.comparisonEq, 'IS'),

  /// An `IS NOT` expression in SQL.
  isNot(Precedence.comparisonEq, 'IS NOT'),

  /// An `IN` expression in SQL.
  $in(Precedence.comparisonEq, 'IN'),

  /// A `NOT IN` expression in SQL.
  notIn(Precedence.comparisonEq, 'NOT IN'),

  /// An `OR` expression in SQL.
  or(Precedence.or, 'OR'),

  /// An `AND` expression in SQL.
  and(Precedence.and, 'AND');

  /// The [Precedence] associated with this binary operator.
  final Precedence precedence;

  /// The default text to generate for this operator.
  ///
  /// Some dialects may chose to override this.
  final String defaultLexeme;

  const BinaryOperator(this.precedence, this.defaultLexeme);

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

  final PhysicalSqlType<T> Function(DriftDialect)? _resolveType;

  /// Create a unary expression from the [operator] and the [operand].
  const UnaryExpression(
    this.operator,
    this.operand, {
    PhysicalSqlType<T> Function(DriftDialect)? resolveType,
  }) : _resolveType = resolveType;

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
  PhysicalSqlType<T> resolveType(DriftDialect dialect) {
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
  not(Precedence.not, true, 'NOT', needsSpace: true),

  /// A bitwise not operation in SQL.
  bitwiseNot(Precedence.unary, true, '~'),

  /// A unary minus in SQL.
  minus(Precedence.unary, true, '-');

  /// The [Precedence] associated with this binary operator.
  final Precedence precedence;

  /// Whether this operator appears before (true) or after (false) the
  /// expression it is applied to in SQL.
  final bool isPrefix;

  /// Whether this operator needs a space character between itself and the
  /// operand.
  final bool needsSpace;

  /// The default text to generate for this operator.
  ///
  /// Some dialects may chose to override this.
  final String defaultLexeme;

  const UnaryOperator(
    this.precedence,
    this.isPrefix,
    this.defaultLexeme, {
    this.needsSpace = false,
  });

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addUnaryOperator(this);
  }
}
