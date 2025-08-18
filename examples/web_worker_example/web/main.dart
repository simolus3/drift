import 'dart:js_interop';

import 'package:drift/wasm.dart';
import 'package:web/web.dart';
import 'package:web_worker_example/database.dart';

void main() async {
  final connection = await WasmDatabase.open(
    databaseName: 'worker',
    sqlite3Uri: Uri.parse('/sqlite3.wasm'),
    driftWorkerUri: Uri.parse('/worker.dart.js'),
  );

  print('Opened WASM database: ${connection.chosenImplementation}');

  final db = MyDatabase(connection.resolvedExecutor);

  final output = document.getElementById('output')!;
  final input = document.getElementById('field')! as HTMLInputElement;
  final submit = document.getElementById('submit')! as HTMLButtonElement;

  db.allEntries().watch().listen((rows) {
    output.innerHTML = ''.toJS;

    for (final row in rows) {
      output.appendChild(HTMLLIElement()..textContent = row.value);
    }
  });

  submit.onClick.listen((event) {
    db.addEntry(input.value);
    input.value = '';
  });
}
