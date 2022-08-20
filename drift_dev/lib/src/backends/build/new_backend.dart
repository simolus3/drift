import 'package:logging/logging.dart';
import 'package:build/build.dart';
import 'package:build/build.dart' as build;

import '../../analysis/backend.dart';

class DriftBuildBackend extends DriftBackend {
  final BuildStep _buildStep;

  DriftBuildBackend(this._buildStep);

  @override
  Logger get log => build.log;

  @override
  Future<String> readAsString(Uri uri) {
    return _buildStep.readAsString(AssetId.resolve(uri));
  }
}
