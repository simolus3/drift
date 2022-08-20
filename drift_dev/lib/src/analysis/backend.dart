import 'package:logging/logging.dart';

abstract class DriftBackend {
  Logger get log;

  Future<String> readAsString(Uri uri);
}
