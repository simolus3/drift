import 'dart:convert';
import 'dart:typed_data';

/// Converts [Uint8List]s to binary strings. Used internally by drift to store
/// a database inside `window.localStorage`.
const bin2str = _BinaryStringConversion();

class _BinaryStringConversion extends Codec<List<int>, String> {
  const _BinaryStringConversion();

  @override
  String encode(List<int> input) => utf8.decode(input);
  @override
  Uint8List decode(String input) => utf8.encode(input);

  @override
  Converter<String, List<int>> get decoder => const Utf8Encoder();

  @override
  Converter<List<int>, String> get encoder => const Utf8Decoder();
}
