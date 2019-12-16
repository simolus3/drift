import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';

import 'driver.dart';

class CommonBackend extends Backend {
  final MoorDriver driver;

  CommonBackend(this.driver);

  @override
  Uri resolve(Uri base, String import) {
    return Uri.parse(driver.absolutePath(Uri.parse(import), base: base));
  }
}

class CommonTask extends BackendTask {
  @override
  final Uri entrypoint;
  final MoorDriver driver;

  CommonTask(this.entrypoint, this.driver);

  @override
  final Logger log = Logger.root;

  @override
  Future<CompilationUnit> parseSource(String dart) async {
    return null;
  }

  @override
  Future<String> readMoor(Uri uri) async {
    final path = driver.absolutePath(uri, base: entrypoint);
    return driver.readFile(path);
  }

  @override
  Future<LibraryElement> resolveDart(Uri uri) async {
    final path = driver.absolutePath(uri, base: entrypoint);
    if (!await driver.isDartLibrary(path)) {
      throw NotALibraryException(uri);
    }

    return await driver.resolveDart(path);
  }

  @override
  Future<bool> exists(Uri uri) {
    return Future.value(driver.doesFileExist(uri.path));
  }
}
