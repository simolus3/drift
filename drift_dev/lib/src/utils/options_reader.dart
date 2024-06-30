import 'package:build_config/build_config.dart';
import 'package:collection/collection.dart';
import 'package:drift_dev/src/analysis/options.dart';

Future<DriftOptions> fromRootDir(String path) async {
  final options = await BuildConfig.fromPackageDir(path);
  return readOptionsFromConfig(options);
}

DriftOptions readOptionsFromConfig(BuildConfig config) {
  return config.buildTargets.values
          .expand((t) {
            const driftBuilders = {
              'drift_dev:drift_dev',
              'drift_dev:not_shared',
              'drift_dev:modular'
            };

            return [
              for (final MapEntry(:key, :value) in t.builders.entries)
                if (value.isEnabled && driftBuilders.contains(key))
                  value.options
            ];
          })
          .map((json) => DriftOptions.fromJson(json))
          .firstOrNull ??
      DriftOptions.defaults();
}
