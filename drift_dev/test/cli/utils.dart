import 'dart:io';
import 'dart:isolate';

import 'package:drift_dev/src/cli/cli.dart';
import 'package:package_config/package_config.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:path/path.dart' as p;

class TestDriftProject {
  final Directory root;

  TestDriftProject(this.root);

  Future<void> runDriftCli(Iterable<String> args) {
    return IOOverrides.runZoned(
      () => DriftDevCli().run(args),
      getCurrentDirectory: () => root,
    );
  }

  Future<void> validate(d.Descriptor descriptor) {
    return descriptor.validate(root.path);
  }

  Future<void> validateDir(Iterable<d.Descriptor> descriptors) {
    return Future.wait(descriptors.map(validate));
  }

  static Future<TestDriftProject> create([
    Iterable<d.Descriptor> packageContent = const Iterable.empty(),
  ]) async {
    final hasPubspec = packageContent.any((e) => e.name == 'pubspec.yaml');
    final actualContents = [...packageContent];
    final appRoot = p.join(d.sandbox, 'app');

    if (!hasPubspec) {
      actualContents.add(d.file('pubspec.yaml', '''
name: app

environment:
  sdk: ^3.0.0

dependencies:
  drift:
dev_dependencies:
  drift_dev:
'''));
    }

    // Instead of running `pub get` for each test, we just copy the package
    // config used by drift_dev over.
    final uri = await Isolate.packageConfig;
    final config =
        PackageConfig.parseBytes(await File.fromUri(uri!).readAsBytes(), uri);

    final driftDevUrl =
        config.packages.singleWhere((e) => e.name == 'drift_dev').root;
    final moorUrl = driftDevUrl.resolve('../extras/assets/old_moor_package/');
    final moorFlutterUrl =
        driftDevUrl.resolve('../extras/assets/old_moor_flutter_package/');

    final appUri = '${File(appRoot).absolute.uri}/';
    final newConfig = PackageConfig([
      ...config.packages,
      Package('app', Uri.parse(appUri),
          packageUriRoot: Uri.parse('${appUri}lib/')),
      // Also include old moor packages to test migration from moor to drift
      Package('moor', moorUrl, packageUriRoot: Uri.parse('${moorUrl}lib/')),
      Package('moor_flutter', moorFlutterUrl,
          packageUriRoot: Uri.parse('${moorFlutterUrl}lib/')),
    ]);
    final configBuffer = StringBuffer();
    PackageConfig.writeString(newConfig, configBuffer);

    actualContents.add(d.dir('.dart_tool', [
      d.file('package_config.json', configBuffer.toString()),
    ]));

    await d.dir('app', actualContents).create();

    return TestDriftProject(Directory(appRoot));
  }
}
