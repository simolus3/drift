import 'package:moor/moor.dart';
import 'package:test/test.dart';

void main() {
  final nullable =
      GeneratedColumn<DateTime>('name', 'table', true, typeName: 'INTEGER');
  final nonNull =
      GeneratedColumn<DateTime>('name', 'table', false, typeName: 'INTEGER');

  test('should write column definition', () {
    final nonNullQuery = GenerationContext.fromDb(null);
    final nullableQuery = GenerationContext.fromDb(null);
    nonNull.writeColumnDefinition(nonNullQuery);
    nullable.writeColumnDefinition(nullableQuery);

    expect(nullableQuery.sql, equals('name INTEGER NULL'));
    expect(nonNullQuery.sql, equals('name INTEGER NOT NULL'));
  });

  test('can compare', () {
    final ctx = GenerationContext.fromDb(null);
    nonNull.isSmallerThan(currentDateAndTime).writeInto(ctx);

    expect(ctx.sql, "name < strftime('%s', CURRENT_TIMESTAMP)");
  });
}
