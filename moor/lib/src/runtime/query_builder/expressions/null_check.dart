part of '../query_builder.dart';

/// Expression that is true if the inner expression resolves to a null value.
@Deprecated('Use isNull through the SqlIsNull extension')
Expression<bool> isNull(Expression inner) => _NullCheck(inner, true);

/// Expression that is true if the inner expression resolves to a non-null
/// value.
@Deprecated('Use isNotNull through the SqlIsNull extension')
Expression<bool> isNotNull(Expression inner) => _NullCheck(inner, false);

/// Extension defines the `isNull` and `isNotNull` members to check whether the
/// expression evaluates to null or not.
extension SqlIsNull on Expression {
  /// Expression that is true if the inner expression resolves to a null value.
  Expression<bool> isNull() => _NullCheck(this, true);

  /// Expression that is true if the inner expression resolves to a non-null
  /// value.
  Expression<bool> isNotNull() => _NullCheck(this, false);
}

/// Evaluates to the first expression in [expressions] that's not null, or
/// null if all [expressions] evaluate to null.
Expression<T> coalesce<T>(List<Expression<T?>> expressions) {
  assert(expressions.length >= 2,
      'coalesce must have at least 2 arguments, got ${expressions.length}');

  return FunctionCallExpression<T>('COALESCE', expressions);
}

class _NullCheck extends Expression<bool> {
  final Expression _inner;
  final bool _isNull;

  @override
  final Precedence precedence = Precedence.comparisonEq;

  _NullCheck(this._inner, this._isNull);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _inner);

    context.buffer.write(' IS ');
    if (!_isNull) {
      context.buffer.write('NOT ');
    }
    context.buffer.write('NULL');
  }

  @override
  int get hashCode => $mrjf($mrjc(_inner.hashCode, _isNull.hashCode));

  @override
  bool operator ==(dynamic other) {
    return other is _NullCheck &&
        other._inner == _inner &&
        other._isNull == _isNull;
  }
}
