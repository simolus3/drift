import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' hide log;
import 'package:build/build.dart' as build show log;
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';

class BuildBackend extends Backend {
  BuildBackendTask createTask(BuildStep step) {
    return BuildBackendTask(step);
  }
}

class BuildBackendTask extends BackendTask {
  final BuildStep step;

  BuildBackendTask(this.step);

  @override
  Uri get entrypoint => step.inputId.uri;

  AssetId _resolve(Uri uri) {
    return AssetId.resolve(uri.toString(), from: step.inputId);
  }

  @override
  Future<String> readMoor(Uri uri) {
    return step.readAsString(_resolve(uri));
  }

  @override
  Future<LibraryElement> resolveDart(Uri uri) {
    return step.resolver.libraryFor(_resolve(uri));
  }

  @override
  Future<CompilationUnit> parseSource(String dart) async {
    return null;
  }

  @override
  Logger get log => build.log;
}
