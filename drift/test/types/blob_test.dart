import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  test('maps without transormation', () {
    const type = BlobType();
    final data = Uint8List.fromList(List.generate(256, (i) => i));

    expect(type.mapToSqlVariable(data), data);
    expect(type.mapFromDatabaseResponse(data), data);
  });

  test('writes blob literals', () {
    const type = BlobType();
    const hex = '67656E6572616C206B656E6F626921';
    final data = Uint8List.fromList(utf8.encode('general kenobi!'));

    expect(type.mapToSqlConstant(data), equalsIgnoringCase("x'$hex'"));
  });
}
