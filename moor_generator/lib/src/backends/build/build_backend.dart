import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/backends/backend.dart';

class BuildBackend extends Backend {}

class BuildBackendTask extends BackendTask {
  final BuildStep step;

  BuildBackendTask(this.step);

  @override
  String get entrypoint => step.inputId.path;

  AssetId _resolve(String uri) {
    return AssetId.resolve(uri, from: step.inputId);
  }

  @override
  Future<String> readMoor(String path) {
    return step.readAsString(_resolve(path));
  }

  @override
  Future<LibraryElement> resolveDart(String path) {
    return step.resolver.libraryFor(_resolve(path));
  }
}
