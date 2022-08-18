import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/src/web/binary_string_conversion.dart';
import 'package:test/test.dart';

void main() {
  final data = Uint8List(256 * 2);
  final encodedBuilder = StringBuffer();
  for (var i = 0; i < 256; i++) {
    data[i] = i % 256;
    encodedBuilder.writeCharCode(i % 256);
  }
  encodedBuilder.write('\u0000' * 256);
  final encoded = encodedBuilder.toString();

  test('converts binary data from and to strings', () {
    final asStr = bin2str.encode(data);
    expect(asStr, encoded);

    final backToBin = bin2str.decode(asStr);

    expect(backToBin, data);
  });

  test('can encode large data', () {
    bin2str.encode(List.filled(0xfffff, 42));
  });

  test('compatible with previous implementation', () {
    expect(_bin2str.encode(data), bin2str.encode(data));
    expect(_bin2str.decode(encoded), bin2str.decode(encoded));
  });
}

// Previous implementation used by drift before switching to `latin1`. Copied
// here to test compatibility.
const _bin2str = _BinaryStringConversion();

class _BinaryStringConversion extends Codec<Uint8List, String> {
  const _BinaryStringConversion();

  @override
  Converter<String, Uint8List> get decoder => const _String2Bin();

  @override
  Converter<Uint8List, String> get encoder => const _Bin2String();
}

class _String2Bin extends Converter<String, Uint8List> {
  const _String2Bin();

  @override
  Uint8List convert(String input) {
    final codeUnits = input.codeUnits;
    final list = Uint8List(codeUnits.length);

    for (var i = 0; i < codeUnits.length; i++) {
      list[i] = codeUnits[i];
    }
    return list;
  }
}

class _Bin2String extends Converter<Uint8List, String> {
  const _Bin2String();

  // There is a browser limit on the amount of chars one can give to
  // String.fromCharCodes https://github.com/sql-js/sql.js/wiki/Persisting-a-Modified-Database#save-a-database-to-a-string
  static const int _chunkSize = 0xffff;

  @override
  String convert(Uint8List input) {
    final buffer = StringBuffer();

    for (var pos = 0; pos < input.length; pos += _chunkSize) {
      final endPos = math.min(pos + _chunkSize, input.length);
      buffer.write(String.fromCharCodes(input.sublist(pos, endPos)));
    }

    return buffer.toString();
  }
}
