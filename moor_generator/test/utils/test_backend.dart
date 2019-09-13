import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';

class TestBackend extends Backend {
  final Map<AssetId, String> fakeContent;
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
    resolveSources(fakeContent.map((k, v) => MapEntry(k.toString(), v)), (r) {
      _resolver = r;
      _initCompleter.complete();
      return _finish.future;
    });
  }

  BackendTask startTask(Uri uri) {
    return _TestBackendTask(this, uri);
  }

  void finish() {
    _finish.complete();
  }

  @override
  Uri resolve(Uri base, String import) {
    final from = AssetId.resolve(base.toString());
    return AssetId.resolve(import, from: from).uri;
  }
}

class _TestBackendTask extends BackendTask {
  final TestBackend backend;

  @override
  final Uri entrypoint;

  @override
  Logger get log => null;

  _TestBackendTask(this.backend, this.entrypoint);

  @override
  Future<String> readMoor(Uri path) async {
    await backend._ready;
    return backend.fakeContent[AssetId.resolve(path.toString())];
  }

  @override
  Future<LibraryElement> resolveDart(Uri path) async {
    await backend._ready;
    return await backend._resolver.libraryFor(AssetId.resolve(path.toString()));
  }

  @override
  Future<CompilationUnit> parseSource(String dart) {
    return null;
  }

  @override
  Future<bool> exists(Uri uri) async {
    return backend.fakeContent.containsKey(AssetId.resolve(uri.toString()));
  }
}
