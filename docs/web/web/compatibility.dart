import 'dart:html';

import 'package:drift/wasm.dart';
import 'package:drift_docs/site.dart' as i0;
import 'package:docsy/main.dart' as i1;

void main() async {
  i0.built_site_main();
  i1.built_site_main();

  final btn = querySelector('#drift-compat-btn')!;
  final results = querySelector('#drift-compat-results')!;

  await for (final _ in btn.onClick) {
    btn.attributes['disabled'] = 'true';
    results.innerText = '';

    try {
      final db = await WasmDatabase.open(
        databaseName: 'test_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );

      results.innerText += '''
Chosen implementation: ${db.chosenImplementation}
Features missing: ${db.missingFeatures}
''';
    } catch (e, s) {
      results.innerText += 'Error: $e, Trace: \n$s';
    } finally {
      btn.attributes.remove('disabled');
    }
  }
}
