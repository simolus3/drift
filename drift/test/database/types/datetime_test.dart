import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../test_utils/test_utils.dart';

void main() {
  final nullable = GeneratedColumn<DateTime>('name', 'table', true,
      type: DriftSqlType.dateTime);
  final nonNull = GeneratedColumn<DateTime>('name', 'table', false,
      type: DriftSqlType.dateTime);

  test('should write column definition', () {
    final nonNullQuery = stubContext();
    final nullableQuery = stubContext();
    nonNull.writeColumnDefinition(nonNullQuery);
    nullable.writeColumnDefinition(nullableQuery);

    expect(nullableQuery.sql, equals('name INTEGER NULL'));
    expect(nonNullQuery.sql, equals('name INTEGER NOT NULL'));
  });

  test('can compare', () {
    final ctx = stubContext();
    nonNull.isSmallerThan(currentDateAndTime).writeInto(ctx);

    expect(ctx.sql, "name < strftime('%s', CURRENT_TIMESTAMP)");
  });
}
