import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  test('int column writes AUTOINCREMENT constraint', () {
    final column = GeneratedColumn<int>(
      'foo',
      'tbl',
      false,
      type: const IntType(),
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
    );

    final context = GenerationContext.fromDb(TodoDb());
    column.writeColumnDefinition(context);

    expect(
        context.sql, equals('foo INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT'));
  });

  test('int column writes PRIMARY KEY constraint', () {
    final column = GeneratedColumn<int>('foo', 'tbl', false,
        type: const IntType(), $customConstraints: 'NOT NULL PRIMARY KEY');

    final context = GenerationContext.fromDb(TodoDb());
    column.writeColumnDefinition(context);

    expect(context.sql, equals('foo INTEGER NOT NULL PRIMARY KEY'));
  });
}
