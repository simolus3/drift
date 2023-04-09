import 'package:meta/meta.dart';

import '../query_builder.dart';

/// `CASE WHEN` expression **without** base expression in sqlite.
///
/// This expression evaluates to the first value in [BaseCaseWhenExpression.orderedCases]
/// for which its key evaluates to `true`.
///
/// See [BaseCaseWhenExpression] for more info.
class CaseWhenExpression<R extends Object>
    extends BaseCaseWhenExpression<bool, R> {
  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// This expression evaluates to the first value in [cases]
  /// for which its key evaluates to `true`.
  ///
  /// If [cases] is empty - throws [ArgumentError]
  CaseWhenExpression({
    required List<CaseWhen<bool, R>> cases,
    Expression<R>? orElse,
  }) : super._(null, cases, orElse);
}

/// `CASE WHEN` expression **with** base expression in sqlite.
///
/// For internal use. Must be used via [Expression.caseMatch]
///
/// See [BaseCaseWhenExpression] for more info.
@internal
class CaseWhenExpressionWithBase<T extends Object, R extends Object>
    extends BaseCaseWhenExpression<T, R> {
  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// If [cases] is empty - throws [ArgumentError]
  CaseWhenExpressionWithBase(
    Expression<T> base, {
    required List<CaseWhen<T, R>> cases,
    Expression<R>? orElse,
  }) : super._(base, cases, orElse);
}

/// A single when-then case for `CASE WHEN` expression in sqlite.
///
/// TODO check if it should be replaced with multiple return values.
///
/// [Multiple return values GitHub issue](https://github.com/dart-lang/language/issues/68)
class CaseWhen<T extends Object, R extends Object> {
  /// Expression to use after `WHEN`
  final Expression<T> when;

  /// Expression to use after `THEN`
  final Expression<R> then;

  /// Creates a single case with expression for when and expression for then.
  const CaseWhen(this.when, {required this.then});
}

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
@internal
abstract class BaseCaseWhenExpression<T extends Object, R extends Object>
    extends Expression<R> {
  /// The optional base expression.
  ///
  /// If it is set, the keys in [orderedCases] will be compared to this expression.
  final Expression? base;

  /// The when-then entries for this expression.
  ///
  /// This expression will evaluate to the value of the entry with a matching key.
  final List<CaseWhen<T, R>> orderedCases;

  /// The expression to use if no entry in [orderedCases] matched.
  final Expression<R>? orElse;

  /// Creates a `CASE WHEN` expression from the independent components.
  ///
  /// If [orderedCases] list is empty - throws [ArgumentError]
  BaseCaseWhenExpression._(this.base, this.orderedCases, this.orElse) {
    if (orderedCases.isEmpty) {
      throw ArgumentError.value(
        orderedCases,
        'orderedCases',
        'Must not be empty',
      );
    }
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('CASE');

    if (base != null) {
      context.buffer.write(' ');
      base!.writeInto(context);
    }

    for (final specificCase in orderedCases) {
      context.buffer.write(' WHEN ');
      specificCase.when.writeInto(context);
      context.buffer.write(' THEN ');
      specificCase.then.writeInto(context);
    }

    final orElse = this.orElse;
    if (orElse != null) {
      context.buffer.write(' ELSE ');
      orElse.writeInto(context);
    }

    context.buffer.write(' END');
  }
}
