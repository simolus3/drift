import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  test('bool with underlying string', () {
    const type = BoolType();

    expect(type.mapFromDatabaseResponse('FALSE'), false);
    expect(type.mapFromDatabaseResponse('TRUE'), true);
  });

  test('writes bool literals', () {
    const type = BoolType();

    expect(type.mapToSqlConstant(false), '0');
    expect(type.mapToSqlConstant(true), '1');
  });
}
