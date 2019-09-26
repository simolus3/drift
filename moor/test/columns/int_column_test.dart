import 'package:moor/src/runtime/components/component.dart';
import 'package:test/test.dart';
import 'package:moor/moor.dart';

import '../data/tables/todos.dart';

void main() {
  test('int column writes AUTOINCREMENT constraint', () {
    final column = GeneratedIntColumn(
      'foo',
      'tbl',
      false,
      declaredAsPrimaryKey: true,
      hasAutoIncrement: true,
    );

    final context = GenerationContext.fromDb(TodoDb(null));
    column.writeColumnDefinition(context);

    expect(
        context.sql, equals('foo INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT'));
  });

  test('int column writes PRIMARY KEY constraint', () {
    final column = GeneratedIntColumn(
      'foo',
      'tbl',
      false,
      declaredAsPrimaryKey: true,
      hasAutoIncrement: false,
    );

    final context = GenerationContext.fromDb(TodoDb(null));
    column.writeColumnDefinition(context);

    expect(context.sql, equals('foo INTEGER NOT NULL PRIMARY KEY'));
  });
}
