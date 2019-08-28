import 'dart:ffi';

bool isNullPointer<T extends NativeType>(Pointer<T> ptr) => ptr == nullptr;
