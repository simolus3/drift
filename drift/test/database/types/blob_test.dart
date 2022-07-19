import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  test('maps without transformation', () {
    final types = DriftDatabaseOptions().types;
    final data = Uint8List.fromList(List.generate(256, (i) => i));

    expect(types.mapToSqlVariable(data), data);
    expect(types.read(DriftSqlType.blob, data), data);
  });

  test('writes blob literals', () {
    final types = DriftDatabaseOptions().types;
    const hex = '67656E6572616C206B656E6F626921';
    final data = Uint8List.fromList(utf8.encode('general kenobi!'));

    expect(types.mapToSqlLiteral(data), equalsIgnoringCase("x'$hex'"));
  });

  test('maps of string', () {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';

    final types = DriftDatabaseOptions().types;
    final data = List.generate(256, (i) => chars[i % chars.length]);
    final dataString = data.join();
    final dataInt = data.map((e) => e.codeUnits[0]).toList();
    final dataUint8 = Uint8List.fromList(dataInt);
    expect(types.read(DriftSqlType.blob, dataString), dataUint8);
  });
}
