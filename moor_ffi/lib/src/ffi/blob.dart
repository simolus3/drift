import 'dart:convert';
import 'dart:ffi';

import 'dart:typed_data';

import 'package:moor_ffi/src/ffi/utils.dart';

/// Pointer to arbitrary blobs in C.
class CBlob extends Struct<CBlob> {
  @Uint8()
  int data;

  static Pointer<CBlob> allocate(Uint8List blob) {
    final str = Pointer<Uint8>.allocate(count: blob.length);

    final asList = str.asExternalTypedData(count: blob.length) as Uint8List;
    asList.setAll(0, blob);

    return str.cast();
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
    final str = addressOf.cast<Uint8>();
    if (isNullPointer(str)) return null;

    final data = str.asExternalTypedData(count: bytesToRead) as Uint8List;
    return Uint8List.fromList(data);
  }

  /// More efficient version of [readString] that doesn't have to find a nil-
  /// terminator. [length] is the amount of bytes to read. The string will be
  /// decoded via [utf8].
  String readAsStringWithLength(int length) {
    return utf8.decode(read(length));
  }

  /// Reads a 0-terminated string, decoded with utf8.
  ///
  /// Warning: This method is very, very slow. If there is any way to know the
  /// length of the string to read, [readAsStringWithLength] will be orders of
  /// magnitude faster.
  String readString() {
    final str = addressOf;
    if (isNullPointer(str)) return null;

    var len = 0;
    while (str.elementAt(++len).load<CBlob>().data != 0) {}

    final units = read(len);
    return utf8.decode(units);
  }
}
