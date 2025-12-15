import '../compiler.dart';
import 'expression.dart';

/// A single when-then case for `CASE WHEN` expression in sqlite.
typedef CaseWhen<T extends Object, R extends Object> = ({
  Expression<T> when,
  Expression<R> then,
});

/// `CASE WHEN` expression in sqlite.
///
/// This expression evaluates to the first value in [BaseCaseWhenExpression.orderedCases]
/// for which its key evaluates to `true`.
///
/// Supports `CASE WHEN` expression with base expression and without base expression.
///
/// For internal use. Must be used via [CaseWhenExpression] and [CaseWhenExpressionWithBase]
///
/// https://www.sqlite.org/lang_expr.html#the_case_expression
final class CaseWhenExpression<T extends Object, R extends Object>
    extends Expression<R> {
  /// The optional base expression.
  ///
  /// If it is set, the keys in [orderedCases] will be compared to this expression.
  final Expression<T>? base;

  /// The when-then entries for this expression.
  ///
  /// This expression will evaluate to the value of the entry with a matching key.
  final List<CaseWhen<T, R>> orderedCases;

  /// The expression to use if no entry in [orderedCases] matched.
  final Expression<R>? orElse;

  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// If [orderedCases] list is empty - throws [ArgumentError]
  CaseWhenExpression._(this.base, this.orderedCases, this.orElse) {
    if (orderedCases.isEmpty) {
      throw ArgumentError.value(
        orderedCases,
        'orderedCases',
        'Must not be empty',
      );
    }
  }

  /// Creates a `CASE WHEN` expression **with** base expressions in SQL.
  ///
  /// If [cases] is empty - throws [ArgumentError]
  static CaseWhenExpression<T, R> withBase<T extends Object, R extends Object>(
    Expression<T> base, {
    required List<CaseWhen<T, R>> cases,
    Expression<R>? orElse,
  }) {
    return CaseWhenExpression._(base, cases, orElse);
  }

  /// A `CASE WHEN` expression **without** a base expression in sqlite.
  ///
  /// This expression evaluates to the first value in [cases]
  /// for which [CaseWhen.when] evaluates to `true`.
  ///
  /// If [cases] is empty - throws [ArgumentError]
  static CaseWhenExpression<bool, R> conditional<R extends Object>({
    required List<CaseWhen<bool, R>> cases,
    Expression<R>? orElse,
  }) {
    return CaseWhenExpression._(null, cases, orElse);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addCaseWhenExpression(this);
  }
}
