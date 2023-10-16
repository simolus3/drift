import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/transformers.dart';
import 'package:vm_service/vm_service.dart';

final _serviceConnection = StreamController<VmService>.broadcast();
void setServiceConnectionForProviderScreen(VmService service) {
  _serviceConnection.add(service);
}

final serviceProvider = StreamProvider<VmService>((ref) {
  return _serviceConnection.stream.startWith(serviceManager.service!);
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
