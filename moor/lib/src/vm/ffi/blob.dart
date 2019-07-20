import 'dart:convert';
import 'dart:ffi';

import 'dart:typed_data';

/// Pointer to arbitrary blobs that aren't null-terminated.
class CBlob extends Pointer<Uint8> {
  /// Allocate a [CBlob] not managed in and populates it with [dartBlob].
  factory CBlob.allocate(Uint8List dartBlob) {
    final ptr = allocate(count: dartBlob.length);
    for (var i = 0; i < dartBlob.length; ++i) {
      ptr.elementAt(i).store(dartBlob[i]);
    }
    return ptr.cast();
  }

  /// Read the string from C memory into Dart.
  static Uint8List fromC(CBlob str, int length) {
    if (str == null) return null;
    assert(length >= 0);

    final units = Uint8List(length);
    for (var i = 0; i < length; ++i) {
      units[i] = str.elementAt(i).load();
    }

    return units;
  }
}

/// A null-terminated C string.
class CString extends Pointer<Uint8> {
  /// Allocate a [CString] not managed in and populates it with [string].
  factory CString.allocate(String string) {
    final encoded = utf8.encode(string);
    final data = Uint8List(encoded.length + 1) // already filled with zeroes
      ..setAll(0, encoded);

    return CBlob.allocate(data).cast();
  }

  /// Read the string from C memory into Dart.
  static String fromC(CBlob str) {
    if (str == null) return null;
    var len = 0;
    while (str.elementAt(++len).load<int>() != 0) {}

    final list = CBlob.fromC(str, len);
    return utf8.decode(list);
  }
}
