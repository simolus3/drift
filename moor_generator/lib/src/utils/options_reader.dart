//@dart=2.9
import 'package:build_config/build_config.dart';
import 'package:moor_generator/src/analyzer/options.dart';

Future<MoorOptions> fromRootDir(String path) async {
  final options = await BuildConfig.fromPackageDir(path);
  return readOptionsFromConfig(options);
}

MoorOptions readOptionsFromConfig(BuildConfig config) {
  final options = config.buildTargets.values
      .map((t) => t.builders['moor_generator:moor_generator']?.options)
      .where((t) => t != null)
      .map((json) => MoorOptions.fromJson(json));

  final iterator = options.iterator;
  return iterator.moveNext() ? iterator.current : const MoorOptions();
}
