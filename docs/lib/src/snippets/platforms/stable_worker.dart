import 'package:drift/wasm.dart';

// When compiled with dart2js, this file defines a dedicated or shared web
// worker used by drift.
void main() => WasmDatabase.workerMainForOpen();
