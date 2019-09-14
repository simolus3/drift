import 'dart:convert';
import 'dart:ffi';

import 'dart:typed_data';

import 'package:moor_ffi/src/ffi/utils.dart';

/// Pointer to arbitrary blobs in C.
class CBlob extends Struct<CBlob> {
  @Uint8()
  int data;

  static Pointer<CBlob> allocate(Uint8List blob) {
    final str = Pointer<CBlob>.allocate(count: blob.length);
    for (var i = 0; i < blob.length; i++) {
      str.elementAt(i).load<CBlob>().data = blob[i];
    }
    return str;
  }

  /// Allocates a 0-terminated string, encoded as utf8 and read from the
  /// [string].
  static Pointer<CBlob> allocateString(String string) {
    final encoded = utf8.encode(string);
    final data = Uint8List(encoded.length + 1) // already filled with zeroes
      ..setAll(0, encoded);
    return CBlob.allocate(data);
  }

  /// Reads [bytesToRead] bytes from the current position.
  Uint8List read(int bytesToRead) {
    assert(bytesToRead >= 0);
    final str = addressOf;
    if (isNullPointer(str)) return null;

    // todo can we user Pointer.asExternalTypedData here?
    final blob = Uint8List(bytesToRead);
    for (var i = 0; i < bytesToRead; ++i) {
      blob[i] = str.elementAt(i).load<CBlob>().data;
    }
    return blob;
  }

  /// Reads a 0-terminated string, decoded with utf8.
  String readString() {
    final str = addressOf;
    if (isNullPointer(str)) return null;

    var len = 0;
    while (str.elementAt(++len).load<CBlob>().data != 0) {}

    final units = read(len);
    return utf8.decode(units);
  }
}
