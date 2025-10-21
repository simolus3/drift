import 'dart:io';
import 'dart:isolate';

import 'package:jaspr_content/jaspr_content.dart';
import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';

/// A [DataLoader] that contributes the current version of relevant packages
/// used to build the documentation website under the `versions` key.
///
/// Since the current version of drift is used as a dependency overrides, this
/// makes `{{ versions.drift }}` evaluate to the current drift version at the
/// time the site is built.
final class PackageVersionDataLoader implements DataLoader {
  @override
  Future<void> loadData(Page page) async {
    final versions = await _resolvedVersions;
    page.apply(data: {'versions': versions});
  }

  static final _resolvedVersions = _loadPackageVersions();

  static Future<Map<String, String>> _loadPackageVersions() async {
    final uri = await Isolate.packageConfig;
    final config = await loadPackageConfigUri(uri!);

    final resolvedVersions = <String, String>{};
    Future<void> resolvePackage(String package) async {
      final resolvedPackage = config[package];
      if (resolvedPackage == null) {
        return;
      }

      final pubspec = await File(
        resolvedPackage.root.resolve('pubspec.yaml').toFilePath(),
      ).readAsString();
      final parsedPubspec = loadYaml(pubspec);
      resolvedVersions[package] = (parsedPubspec as Map)['version'].toString();
    }

    await Future.wait([
      for (final package in packages) resolvePackage(package),
    ]);
    return resolvedVersions;
  }

  static const packages = [
    'sqlparser',
    'path',
    'build_runner',
    'drift',
    'drift_dev',
    'drift_flutter',
    'drift_postgres',
    'sqlite3',
    'path_provider',
    'postgres',
  ];
}
