import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart' show DynamicTypeImpl;
import 'package:logging/logging.dart';
import 'package:moor_generator/src/backends/backend.dart';

import 'driver.dart';

class CommonBackend extends Backend {
  final MoorDriver driver;

  CommonBackend(this.driver);

  @override
  Uri resolve(Uri base, String import) {
    final absolute = driver.absolutePath(Uri.parse(import), base: base);
    if (absolute == null) return null;

    return Uri.parse(absolute);
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
  Future<DartType> resolveTypeOf(Uri context, String dartExpression) async {
    // todo: Override so that we don't throw. We should support this properly.
    return DynamicTypeImpl.instance;
  }

  @override
  Future<bool> exists(Uri uri) {
    return Future.value(driver.doesFileExist(uri.path));
  }
}
