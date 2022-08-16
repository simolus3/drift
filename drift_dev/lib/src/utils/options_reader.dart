import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:drift_dev/src/analyzer/options.dart';

Future<DriftOptions> fromRootDir(String path) async {
  final options = await BuildConfig.fromPackageDir(path);
  return readOptionsFromConfig(options);
}

DriftOptions readOptionsFromConfig(BuildConfig config) {
  return config.buildTargets.values
          .map((t) {
            return t.builders['drift_dev:drift_dev']?.options ??
                t.builders['drift_dev:not_shared']?.options;
          })
          .whereType<Map>()
          .map((json) => DriftOptions.fromJson(json))
          .firstOrNull ??
      DriftOptions.defaults();
}
