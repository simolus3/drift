part of 'package:moor/moor_web.dart';
/*
const _bin2str = _BinaryStringConversion();

class _BinaryStringConversion extends Encoding {
  const _BinaryStringConversion();

  @override
  Converter<List<int>, String> get decoder => const _Bin2String();

  @override
  Converter<String, List<int>> get encoder => const _String2Bin();

  @override
  String get name => 'bin';
}

class _String2Bin extends Converter<String, Uint8List> {
  const _String2Bin();

  @override
  Uint8List convert(String input) {
    final codeUnits = input.codeUnits;
    final list = Uint8List(codeUnits.length);

    for (var i = 0; i < codeUnits.length; i++) {
      list[i] = i;
    }
    return list;
  }
}

class _Bin2String extends Converter<List<int>, String> {
  const _Bin2String();

  @override
  String convert(List<int> input) {
    final buffer = StringBuffer();
    for (var byte in input) {
      buffer.writeCharCode(byte);
    }
    return buffer.toString();
  }
}
*/
