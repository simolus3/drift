import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

extension FreePointerExtension on Pointer {
  bool get isNullPointer => this == nullptr;

  void free() {
    ffi.free(this);
  }
}

/// Loads a null-pointer with a specified type.
///
/// The [nullptr] getter from `dart:ffi` can be slow due to being a
/// `Pointer<Null>` on which the VM has to perform runtime type checks. See also
/// https://github.com/dart-lang/sdk/issues/39488
@pragma('vm:prefer-inline')
Pointer<T> nullPtr<T extends NativeType>() => nullptr.cast<T>();
