import 'package:moor/moor.dart';
import 'package:test/test.dart';

void main() {
  final nullable = GeneratedDateTimeColumn('name', null, true);
  final nonNull = GeneratedDateTimeColumn('name', null, false);

  test('should write column definition', () {
    final nonNullQuery = GenerationContext(null, null);
    final nullableQuery = GenerationContext(null, null);
    nonNull.writeColumnDefinition(nonNullQuery);
    nullable.writeColumnDefinition(nullableQuery);

    expect(nullableQuery.sql, equals('name INTEGER NULL'));
    expect(nonNullQuery.sql, equals('name INTEGER NOT NULL'));
  });

  test('can compare', () {
    final ctx = GenerationContext(null, null);
    nonNull.isSmallerThan(currentDateAndTime).writeInto(ctx);

    expect(ctx.sql, "name < strftime('%s', CURRENT_TIMESTAMP)");
  });
}
