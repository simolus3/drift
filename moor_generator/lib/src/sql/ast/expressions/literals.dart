import 'package:built_value/built_value.dart';

import 'expressions.dart';

part 'literals.g.dart';

// https://www.sqlite.org/syntax/literal-value.html

class NullLiteral extends Expression {
  const NullLiteral();

  @override
  String toString() => 'NULL';

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(other) => identical(this, other) || other is NullLiteral;
}

abstract class BooleanLiteral extends Expression
    implements Built<BooleanLiteral, BooleanLiteralBuilder> {
  bool get value;

  BooleanLiteral._();
  factory BooleanLiteral.from(bool value) =>
      BooleanLiteral((b) => b.value = value);

  factory BooleanLiteral(Function(BooleanLiteralBuilder) updates) =
      _$BooleanLiteral;
}

enum CurrentTimeAccessor { currentTime, currentDate, currentTimestamp }

/// Represents the CURRENT_TIME, CURRENT_DATE or CURRENT_TIMESTAMP mode.
abstract class CurrentTimeResolver extends Expression
    implements Built<CurrentTimeResolver, CurrentTimeResolverBuilder> {
  CurrentTimeAccessor get mode;

  CurrentTimeResolver._();
  factory CurrentTimeResolver.mode(CurrentTimeAccessor mode) {
    return CurrentTimeResolver((b) => b.mode = mode);
  }
  factory CurrentTimeResolver(Function(CurrentTimeResolverBuilder) updates) =
      _$CurrentTimeResolver;
}

abstract class NumericLiteral extends Expression
    implements Built<NumericLiteral, NumericLiteralBuilder> {
  num get value;
  NumericLiteral._();
  factory NumericLiteral(Function(NumericLiteralBuilder) updates) =
      _$NumericLiteral;
}

abstract class StringLiteral extends Expression
    implements Built<StringLiteral, StringLiteralBuilder> {
  bool get isBlob;
  String get content;

  StringLiteral._();
  factory StringLiteral(Function(StringLiteralBuilder) updates) =
      _$StringLiteral;
}
