import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';

import 'driver.dart';

class PluginBackend extends Backend {}

class PluginTask extends BackendTask {
  @override
  final Uri entrypoint;
  final MoorDriver driver;

  PluginTask(this.entrypoint, this.driver);

  @override
  final Logger log = Logger.root;

  @override
  Future<CompilationUnit> parseSource(String dart) {
    return null;
  }

  @override
  Future<String> readMoor(Uri uri) async {
    final path = driver.absolutePath(uri, base: entrypoint);
    return driver.readFile(path);
  }

  @override
  Future<LibraryElement> resolveDart(Uri uri) {
    final path = driver.absolutePath(uri, base: entrypoint);
    return driver.dartDriver.currentSession.getLibraryByUri(path);
  }
}
