import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

Builder writeVersions(BuilderOptions options) {
  return _VersionsBuilder();
}

class _VersionsBuilder extends Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    const packages = [
      'sqlparser',
      'path',
      'build_runner',
      'drift',
      'drift_dev',
      'drift_postgres',
    ];

    final versions = <String, String>{};
    for (final package in packages) {
      final pubspec =
          await buildStep.readAsString(AssetId(package, 'pubspec.yaml'));
      final parsedPubspec = loadYaml(pubspec);

      versions[package] = (parsedPubspec as Map)['version'].toString();
    }

    await buildStep.writeAsString(
        buildStep.allowedOutputs.single, json.encode(versions));
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$package$': ['lib/versions.json']
      };
}
