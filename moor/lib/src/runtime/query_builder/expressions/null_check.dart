part of '../query_builder.dart';

/// Expression that is true if the inner expression resolves to a null value.
Expression<bool, BoolType> isNull(Expression inner) => _NullCheck(inner, true);

/// Expression that is true if the inner expression resolves to a non-null
/// value.
Expression<bool, BoolType> isNotNull(Expression inner) =>
    _NullCheck(inner, false);

class _NullCheck extends Expression<bool, BoolType> {
  final Expression _inner;
  final bool _isNull;

  _NullCheck(this._inner, this._isNull);

  @override
  void writeInto(GenerationContext context) {
    _inner.writeInto(context);

    context.buffer.write(' IS ');
    if (!_isNull) {
      context.buffer.write('NOT ');
    }
    context.buffer.write('NULL');
  }
}
