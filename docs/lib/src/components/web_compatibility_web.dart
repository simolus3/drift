import 'package:drift/wasm.dart';
import 'package:jaspr/browser.dart';
import 'package:universal_web/web.dart' as web;

Future<String> determineDriftWasmCompatibility() async {
  final db = await WasmDatabase.open(
    databaseName: 'test_db',
    // These URLs need to be absolute because we're serving this JS file
    // under `/web`.
    sqlite3Uri: Uri.parse('/sqlite3.wasm'),
    driftWorkerUri: Uri.parse('/drift_worker.dart.js'),
  );

  return '''
Chosen implementation: ${db.chosenImplementation}
Features missing: ${db.missingFeatures}
''';
}

extension ResolveDomNode on BuildContext {
  web.Node get node {
    final element = this as BuildableElement;
    final parent =
        element.parentRenderObjectElement!.renderObject as DomRenderObject;

    return parent.node;
  }
}
