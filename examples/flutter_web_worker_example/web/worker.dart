import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen(setupAllDatabases: (database) {
    database.createFunction(
      functionName: 'my_function',
      function: (args) => 'Hello from custom drift worker!',
    );
  });
}
