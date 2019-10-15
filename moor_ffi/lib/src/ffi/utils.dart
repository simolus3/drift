import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

bool isNullPointer<T extends NativeType>(Pointer<T> ptr) => ptr == nullptr;

extension FreePointerExtension<T extends NativeType> on Pointer<T> {
  // todo rename to "free" after https://github.com/dart-lang/sdk/issues/38860
  void $free() {
    ffi.free(this);
  }
}
