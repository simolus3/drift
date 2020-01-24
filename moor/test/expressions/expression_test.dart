import 'package:test/test.dart';

import 'package:moor/moor.dart';
import '../data/utils/expect_generated.dart';

class _UnknownExpr extends Expression {
  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('???');
  }
}

void main() {
  test('precedence ordering', () {
    expect(Precedence.plusMinus < Precedence.mulDivide, isTrue);
    expect(Precedence.unary <= Precedence.unary, isTrue);
    expect(Precedence.postfix >= Precedence.bitwise, isTrue);
    expect(Precedence.postfix > Precedence.primary, isFalse);
  });

  test('puts parentheses around expressions with unknown precedence', () {
    final expr = _UnknownExpr().equalsExp(_UnknownExpr());
    expect(expr, generates('(???) = (???)'));
  });
}
