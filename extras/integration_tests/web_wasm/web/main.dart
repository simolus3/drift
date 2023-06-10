import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

import 'package:drift/wasm.dart';
// ignore: invalid_use_of_internal_member
import 'package:drift/src/web/wasm_setup.dart';

const dbName = 'drift_test';

void main() {
  _addCallbackForWebDriver('detectImplementations', _detectImplementations);

  document.getElementById('selfcheck')?.onClick.listen((event) async {
    print('starting');
    final database = await openDatabase();

    print('selected storage: ${database.chosenImplementation}');
    print('missing features: ${database.missingFeatures}');
  });
}

void _addCallbackForWebDriver(String name, Future Function() impl) {
  setProperty(globalThis, name, allowInterop((Function callback) async {
    Object? result;

    try {
      result = await impl();
    } catch (e, s) {
      final console = getProperty(globalThis, 'console');
      callMethod(console, 'error', [e, s]);
    }

    callMethod(callback, 'call', [null, result]);
  }));
}

Future<String> _detectImplementations() async {
  final opener = _opener;
  await opener.probe();

  return json.encode({
    'impls': opener.availableImplementations.map((r) => r.name).toList(),
    'missing': opener.missingFeatures.map((r) => r.name).toList(),
  });
}

WasmDatabaseOpener get _opener {
  return WasmDatabaseOpener(
    databaseName: dbName,
    sqlite3WasmUri: Uri.parse('/sqlite3.wasm'),
    driftWorkerUri: Uri.parse('/worker.dart.js'),
  );
}

Future<WasmDatabaseResult> openDatabase() async {
  return await _opener.open();
}
