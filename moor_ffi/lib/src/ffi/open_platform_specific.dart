import 'dart:ffi';
import 'dart:io';

String _platformPath(String name, {String path}) {
  final resolvedPath = path ?? '';

  if (Platform.isLinux || Platform.isAndroid) {
    return '${resolvedPath}lib$name.so';
  }
  if (Platform.isMacOS) {
    return '${resolvedPath}lib$name.dylib';
  }
  if (Platform.isWindows) {
    return '$resolvedPath$name.dll';
  }

  throw UnsupportedError('Platform not implemented');
}

DynamicLibrary dlopenPlatformSpecific(String name, {String path}) {
  final resolvedPath = _platformPath(name, path: path);
  return DynamicLibrary.open(resolvedPath);
}
