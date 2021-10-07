// @dart=2.9
import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:moor_generator/src/cli/cli.dart';
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
    {String pubspec, Iterable<d.Descriptor> additional}) {
  pubspec ??= '''
name: app

environment:
  sdk: ^2.12.0

dependencies:
  moor: ^4.4.0
dev_dependencies:
  moor_generator: ^4.4.0
''';

  return d.dir('app', [
    d.dir('lib', lib),
    d.file('pubspec.yaml', pubspec),
    ...?additional
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
    ]).create();
  });
}
