import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

extension FreePointerExtension on Pointer {
  bool get isNullPointer => this == nullptr;

  void free() {
    ffi.free(this);
  }
}
