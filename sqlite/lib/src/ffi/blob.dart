import 'dart:ffi';
import 'dart:typed_data';

import 'arena.dart';

/// Represents a blob in C memory, managed by an [Arena]. The main difference
/// to a [CString] is that blobs aren't null-terminated.
class CBlob extends Pointer<Void> {
  /// Allocates a [CBlob] in the current [Arena] and populates it with
  /// [blob].
  factory CBlob(Uint8List blob) => CBlob.inArena(Arena.current(), blob);

  /// Allocates a [CString] in [arena] and populates it with [blob].
  factory CBlob.inArena(Arena arena, Uint8List blob) =>
      arena.scoped(CBlob.allocate(blob));

  /// Allocate a [CBlob] not managed in and populates it with [dartBlob].
  ///
  /// This [CBlob] is not managed by an [Arena]. Please ensure to [free] the
  /// memory manually!
  factory CBlob.allocate(Uint8List dartBlob) {
    Pointer<Uint8> str = allocate(count: dartBlob.length);
    for (int i = 0; i < dartBlob.length; ++i) {
      str.elementAt(i).store(dartBlob[i]);
    }
    return str.cast();
  }

  /// Read the string for C memory into Dart.
  static Uint8List fromC(CBlob str) {
    if (str == null) return null;
    int len = 0;
    while (str.elementAt(++len).load<int>() != 0);

    final Uint8List units = Uint8List(len);
    for (int i = 0; i < len; ++i) units[i] = str.elementAt(i).load();

    return units;
  }
}
