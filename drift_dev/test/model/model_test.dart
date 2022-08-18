import 'package:drift_dev/src/model/model.dart';
import 'package:test/test.dart';

void main() {
  test('removes leading numbers', () {
    expect(dartNameForSqlColumn('foo'), 'foo');
    expect(dartNameForSqlColumn('123a'), 'a');
  });

  test('removes invalid characters', () {
    expect(dartNameForSqlColumn('a + b * c'), 'abc');
    expect(dartNameForSqlColumn('2a + b'), 'ab');
    expect(dartNameForSqlColumn('1+2'), 'empty');
  });

  test('converts to camelCase', () {
    expect(dartNameForSqlColumn('foo_bar_baz'), 'fooBarBaz');
  });

  test('appends digits to avoid conflicts', () {
    expect(dartNameForSqlColumn('foo', existingNames: []), 'foo');
    expect(dartNameForSqlColumn('foo', existingNames: ['foo']), 'foo1');
    expect(dartNameForSqlColumn('foo', existingNames: ['foo', 'foo1']), 'foo2');
    expect(dartNameForSqlColumn('1+2', existingNames: ['empty']), 'empty1');
  });
}
