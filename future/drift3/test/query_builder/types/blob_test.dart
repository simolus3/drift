import 'dart:convert';
import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

void main() {
  final type = BuiltinDriftType.byteArray.resolveIn(
    const SqliteDialect.withOptions(),
  );

  test('maps without transformation', () {
    final data = Uint8List.fromList(List.generate(256, (i) => i));

    expect(type.sqlParameter(data), data);
    expect(type.dartValue(data), data);
  });

  test('writes blob literals', () {
    const hex = '67656E6572616C206B656E6F626921';
    final data = Uint8List.fromList(utf8.encode('general kenobi!'));

    expect(type.sqlLiteral(data), equalsIgnoringCase("x'$hex'"));
  });

  test('maps of string', () {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';

    final data = List.generate(256, (i) => chars[i % chars.length]);
    final dataString = data.join();
    final dataInt = data.map((e) => e.codeUnits[0]).toList();
    final dataUint8 = Uint8List.fromList(dataInt);
    expect(type.dartValue(dataString), dataUint8);
  });
}
