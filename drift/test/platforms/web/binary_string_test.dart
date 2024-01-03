import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/src/web/binary_string_conversion.dart';
import 'package:test/test.dart';

void main() {
  group("Ascii Range", () {
    // Generate data that is valid in UTF-8 encoding (ASCII range)
    final data = Uint8List(128); // Limiting to ASCII range
    for (var i = 0; i < data.length; i++) {
      data[i] = i; // ASCII characters are valid UTF-8
    }

    // Convert to UTF-8 string
    final encoded = utf8.decode(data, allowMalformed: true);

    test('converts binary data from and to strings', () {
      final asStr = bin2str.encode(data);
      expect(asStr, encoded);

      final backToBin = bin2str.decode(asStr);
      expect(backToBin, data);
    });

    test('can encode large data', () {
      bin2str.encode(Uint8List.fromList(List.filled(0xfffff, 42)));
    });

    test('compatible with previous implementation', () {
      const bin2strOld = _BinaryStringConversion();

      final previousEncoded = utf8.decode(data, allowMalformed: true);
      expect(bin2strOld.encode(data), previousEncoded);
      expect(bin2strOld.decode(previousEncoded), data);
    });
  });

  group("Full UTF-8 Range", () {
    // Combining ASCII and various UTF-8 characters (including emojis)
    final testString = 'Hello, UTF-8 World! 😊 🌍 🔥 💻';

    // Encode the string to Uint8List using UTF-8 encoding
    final data = utf8.encode(testString);

    // Decode the Uint8List back to a string
    final encoded = utf8.decode(data);

    test('converts full range binary data from and to strings', () {
      final asStr = bin2str.encode(Uint8List.fromList(data));
      expect(asStr, encoded);

      final backToBin = bin2str.decode(asStr);
      expect(backToBin, Uint8List.fromList(data));
    });
  });
}

// Previous implementation used by drift before switching to `utf8`. Copied
// here to test compatibility.

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
