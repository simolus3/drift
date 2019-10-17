import 'dart:convert';
import 'dart:ffi';

import 'dart:typed_data';

import 'package:moor_ffi/src/ffi/utils.dart';
import 'package:ffi/ffi.dart' as ffi;

/// Pointer to arbitrary blobs in C.
class CBlob extends Struct {
  static Pointer<CBlob> allocate(Uint8List blob) {
    final str = ffi.allocate<Uint8>(count: blob.length);

    final asList = str.asTypedList(blob.length);
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
}

extension CBlobPointer on Pointer<CBlob> {
  /// Reads a 0-terminated string, decoded with utf8.
  ///
  /// Warning: This method is very, very slow. If there is any way to know the
  /// length of the string to read, [readAsStringWithLength] will be orders of
  /// magnitude faster.
  String readString() {
    if (isNullPointer) return null;

    var len = 0;
    final asUintPointer = cast<Uint8>();
    while (asUintPointer[++len] != 0) {}

    final units = readBytes(len);
    return utf8.decode(units);
  }

  /// More efficient version of [readString] that doesn't have to find a nil-
  /// terminator. [length] is the amount of bytes to read. The string will be
  /// decoded via [utf8].
  String readAsStringWithLength(int length) {
    return utf8.decode(readBytes(length));
  }

  /// Reads [length] bytes from this address.
  Uint8List readBytes(int length) {
    assert(length >= 0);
    if (isNullPointer) return null;

    final data = cast<Uint8>().asTypedList(length);
    return Uint8List.fromList(data);
  }
}
