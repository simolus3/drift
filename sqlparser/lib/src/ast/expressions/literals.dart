import 'expressions.dart';

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
