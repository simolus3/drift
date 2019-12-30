import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' hide log;
import 'package:build/build.dart' as build show log;
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';

class BuildBackend extends Backend {
  BuildBackendTask createTask(BuildStep step) {
    return BuildBackendTask(step, this);
  }

  @override
  Uri resolve(Uri base, String import) {
    final from = AssetId.resolve(base.toString());
    return AssetId.resolve(import, from: from).uri;
  }
}

class BuildBackendTask extends BackendTask {
  final BuildStep step;
  final BuildBackend backend;

  BuildBackendTask(this.step, this.backend);

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
  Future<LibraryElement> resolveDart(Uri uri) async {
    try {
      final library = await step.resolver.libraryFor(_resolve(uri));
      // older versions of the resolver used to return null instead of throwing
      if (library == null) throw NotALibraryException(uri);
      return library;
    } on NonLibraryAssetException catch (_) {
      throw NotALibraryException(uri);
    }
  }

  @override
  Future<CompilationUnit> parseSource(String dart) async {
    return null;
  }

  @override
  Logger get log => build.log;

  @override
  Future<bool> exists(Uri uri) {
    return step.canRead(_resolve(uri));
  }
}
