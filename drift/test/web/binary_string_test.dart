import 'dart:typed_data';

import 'package:drift/src/web/binary_string_conversion.dart';
import 'package:test/test.dart';

void main() {
  final data = Uint8List(256 * 2);
  for (var i = 0; i < 256; i++) {
    data[i] = i % 256;
  }

  test('converts binary data from and to strings', () {
    final asStr = bin2str.encode(data);
    final backToBin = bin2str.decode(asStr);

    expect(backToBin, data);
  });
}
