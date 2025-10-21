import 'dart:js_interop';

import 'package:drift/wasm.dart';
import 'package:jaspr/browser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:universal_web/web.dart' as web;

import 'search/component_client.dart';

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

Component searchModalImpl() {
  return SearchModalImpl();
}

final ProviderContainer rootContainer = ProviderContainer(
  observers: [_ErrorLogger()],
);

final class _ErrorLogger extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    super.providerDidFail(context, error, stackTrace);

    web.console.error(
      <JSAny>[
        'Provider failed: ${context.provider.name}'.toJS,
        error.toString().toJS,
        stackTrace.toString().toJS,
      ].toJS,
    );
  }
}
