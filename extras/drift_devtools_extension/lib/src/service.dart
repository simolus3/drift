import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/wasm.dart';
import 'package:vm_service/vm_service.dart';

final _serviceConnection = StreamController<VmService>.broadcast();
void setServiceConnectionForProviderScreen(VmService service) {
  _serviceConnection.add(service);
}

extension<T> on ValueListenable<T> {
  Stream<T> get asStream {
    return Stream.multi((listener) {
      listener.add(value);

      void valueListener() {
        print('current state: $value');
        listener.add(value);
      }

      void addListener() {
        this.addListener(valueListener);
      }

      void removeListener() {
        this.removeListener(valueListener);
      }

      addListener();
      listener
        ..onPause = removeListener
        ..onResume = addListener
        ..onCancel = removeListener;
    });
  }
}

final serviceProvider = StreamProvider<VmService>((ref) {
  final state = serviceManager.connectedState.asStream;
  return state.where((c) => c.connected).map((_) => serviceManager.service!);
});

final _libraryEvalProvider =
    FutureProviderFamily<EvalOnDartLibrary, String>((ref, libraryPath) async {
  final service = await ref.watch(serviceProvider.future);

  final eval = EvalOnDartLibrary(
    libraryPath,
    service,
    serviceManager: serviceManager,
  );
  ref.onDispose(eval.dispose);
  return eval;
});

final driftEvalProvider =
    _libraryEvalProvider('package:drift/src/runtime/devtools/devtools.dart');

final hotRestartEventProvider =
    ChangeNotifierProvider<ValueNotifier<void>>((ref) {
  final selectedIsolateListenable =
      serviceManager.isolateManager.selectedIsolate;

  // Since ChangeNotifierProvider calls `dispose` on the returned ChangeNotifier
  // when the provider is destroyed, we can't simply return `selectedIsolateListenable`.
  // So we're making a copy of it instead.
  final notifier = ValueNotifier<IsolateRef?>(selectedIsolateListenable.value);

  void listener() => notifier.value = selectedIsolateListenable.value;
  selectedIsolateListenable.addListener(listener);
  ref.onDispose(() => selectedIsolateListenable.removeListener(listener));

  return notifier;
});

final sqliteProvider = FutureProvider((ref) async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  return sqlite;
});
