import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  test('maps without transformation', () {
    const type = BoolType();
    const data = false;

    expect(type.mapToSqlVariable(data), 0);
    expect(type.mapFromDatabaseResponse(data), data);
  });

  test('writes bool literals', () {
    const type = BoolType();
    const data = false;

    expect(type.mapToSqlConstant(data), '0');
  });
}
