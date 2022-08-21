import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';

abstract class DriftBackend {
  Logger get log;

  Future<String> readAsString(Uri uri);
  Future<LibraryElement> readDart(Uri uri);
}
