import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';

void main() {
  final nullable = GeneratedDateTimeColumn('name', true);
  final nonNull = GeneratedDateTimeColumn('name', false);

  test('should write column definition', () {
    final nullableBuff = StringBuffer();
    final nonNullBuff = StringBuffer();
    nullable.writeColumnDefinition(nullableBuff);
    nonNull.writeColumnDefinition(nonNullBuff);

    expect(nullableBuff.toString(), equals('name INTEGER NULL'));
    expect(nonNullBuff.toString(), equals('name INTEGER NOT NULL'));
  });
}
