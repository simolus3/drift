import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/open.dart';

void main() {
  open.overrideFor(OperatingSystem.linux, _openOnLinux);

  // After setting all the overrides, you can use drift!
}

DynamicLibrary _openOnLinux() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final libraryNextToScript = File('${scriptDir.path}/sqlite3.so');
  return DynamicLibrary.open(libraryNextToScript.path);
}
// _openOnWindows could be implemented similarly by opening `sqlite3.dll`
