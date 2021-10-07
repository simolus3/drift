// @dart=2.9
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:moor_generator/src/cli/cli.dart';
import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart' as p;
import 'package:test/scaffolding.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

@isTest
void _test(String desc, Function() body) {
  test(desc, () {
    return IOOverrides.runZoned(
      body,
      getCurrentDirectory: () => Directory('${d.sandbox}/app'),
    );
  });
}

Future<void> _apply() {
  return MoorCli().run(['migrate']);
}

Future<void> _setup(Iterable<d.Descriptor> lib,
    {String pubspec, Iterable<d.Descriptor> additional}) async {
  // Copy and patch moor_generator's package config instead of running `pub get`
  // in each test.

  final uri = await Isolate.packageConfig;
  final config =
      PackageConfig.parseBytes(await File.fromUri(uri).readAsBytes(), uri);

  final appUri = '${File(p.join(d.sandbox, 'app')).absolute.uri}/';
  final newConfig = PackageConfig([
    ...config.packages,
    Package('app', Uri.parse(appUri),
        packageUriRoot: Uri.parse('${appUri}lib/')),
  ]);
  final configBuffer = StringBuffer();
  PackageConfig.writeString(newConfig, configBuffer);

  pubspec ??= '''
name: app

environment:
  sdk: ^2.12.0

dependencies:
  moor: ^4.4.0
dev_dependencies:
  moor_generator: ^4.4.0
''';

  await d.dir('app', [
    d.dir('lib', lib),
    d.file('pubspec.yaml', pubspec),
    d.dir('.dart_tool', [
      d.file('package_config.json', configBuffer.toString()),
    ]),
    ...?additional,
  ]).create();
}

void main() {
  _test('renames moor files', () async {
    await _setup([
      d.file('a.moor', "import 'b.moor';"),
      d.file('b.moor', 'CREATE TABLE foo (x TEXT);'),
    ]);

    await _apply();

    await d.dir('app/lib', [
      d.file('a.drift', "import 'b.drift';"),
      d.file('b.drift', 'CREATE TABLE foo (x TEXT);'),
    ]).validate();
  });

  _test('patches moor imports', () async {
    await _setup([
      d.file('a.dart', '''
import 'package:moor/moor.dart' as moor;
import 'package:moor/extensions/moor_ffi.dart';
import 'package:moor/src/some/internal/file.dart';

export 'package:moor/moor_web.dart';
export 'package:moor/fFI.dart';
'''),
    ]);

    await _apply();

    await d.dir('app/lib', [
      d.file('a.dart', '''
import 'package:drift/drift.dart' as moor;
import 'package:drift/extensions/native.dart';
import 'package:drift/src/some/internal/file.dart';

export 'package:drift/web.dart';
export 'package:drift/native.dart';
'''),
    ]).validate();
  });
}
