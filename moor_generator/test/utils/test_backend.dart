import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:moor_generator/src/backends/backend.dart';

class TestBackend extends Backend {
  final Map<String, String> fakeContent;
  Resolver _resolver;

  final Completer _initCompleter = Completer();
  final Completer _finish = Completer();

  /// Future that completes when this backend is ready, which happens when all
  /// input files have been parsed and analyzed by the Dart analyzer.
  Future get _ready => _initCompleter.future;

  TestBackend(this.fakeContent) {
    _init();
  }

  void _init() {
    resolveSources(fakeContent, (r) {
      _resolver = r;
      _initCompleter.complete();
      return _finish.future;
    });
  }

  BackendTask startTask(String path) {
    return _TestBackendTask(this, path);
  }

  void finish() {
    _finish.complete();
  }
}

class _TestBackendTask extends BackendTask {
  final TestBackend backend;

  @override
  final String entrypoint;

  _TestBackendTask(this.backend, this.entrypoint);

  @override
  Future<String> readMoor(String path) async {
    await backend._ready;
    return backend.fakeContent[path];
  }

  @override
  Future<LibraryElement> resolveDart(String path) async {
    await backend._ready;
    return await backend._resolver.libraryFor(AssetId.parse(path));
  }
}
