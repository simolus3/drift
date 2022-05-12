import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:drift_dev/src/cli/cli.dart';
import 'package:meta/meta.dart';
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
    {String? pubspec, Iterable<d.Descriptor>? additional}) async {
  // Copy and patch moor_generator's package config instead of running `pub get`
  // in each test.

  final uri = await Isolate.packageConfig;
  final config =
      PackageConfig.parseBytes(await File.fromUri(uri!).readAsBytes(), uri);

  final driftDevUrl =
      config.packages.singleWhere((e) => e.name == 'drift_dev').root;
  final moorFlutterUrl = driftDevUrl.resolve('../moor_flutter/');

  final appUri = '${File(p.join(d.sandbox, 'app')).absolute.uri}/';
  final newConfig = PackageConfig([
    ...config.packages,
    Package('app', Uri.parse(appUri),
        packageUriRoot: Uri.parse('${appUri}lib/')),
    // Need to fake moor_flutter because drift_dev can't depend on Flutter
    // packages
    Package('moor_flutter', moorFlutterUrl,
        packageUriRoot: Uri.parse('${moorFlutterUrl}lib/')),
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

  _test('updates identifier names', () async {
    await _setup([
      d.file('a.dart', '''
import 'package:moor/moor.dart';
import 'package:moor/ffi.dart' as ffi;
import 'package:moor/isolate.dart' as isolate;
import 'package:moor/remote.dart';
import 'package:moor/moor_web.dart';

class MyStorage extends MoorWebStorage {
  Never noSuchMethod(Invocation i) => throw '';
}

ffi.VmDatabase _openConnection() {
  return ffi.VmDatabase.memory();
}

@UseMoor()
class Database {}

void main() {
  moorRuntimeOptions = MoorRuntimeOptions()
    ..debugPrint = moorRuntimeOptions.debugPrint;
  MoorServer(DatabaseConnection.fromExecutor(_openConnection()));

  try {
    Database();
  } on MoorWrappedException {
    // a comment here, why not
  }
}
'''),
    ]);

    await _apply();

    await d.dir('app/lib', [
      d.file('a.dart', '''
import 'package:drift/drift.dart';
import 'package:drift/native.dart' as ffi;
import 'package:drift/isolate.dart' as isolate;
import 'package:drift/remote.dart';
import 'package:drift/web.dart';

class MyStorage extends DriftWebStorage {
  Never noSuchMethod(Invocation i) => throw '';
}

ffi.NativeDatabase _openConnection() {
  return ffi.NativeDatabase.memory();
}

@DriftDatabase()
class Database {}

void main() {
  driftRuntimeOptions = DriftRuntimeOptions()
    ..debugPrint = driftRuntimeOptions.debugPrint;
  DriftServer(DatabaseConnection.fromExecutor(_openConnection()));

  try {
    Database();
  } on DriftWrappedException {
    // a comment here, why not
  }
}
'''),
    ]).validate();
  });

  _test('patches include args from @UseMoor and @UseDao', () async {
    await _setup([
      d.file('a.dart', '''
import 'package:moor/moor.dart';

@UseMoor(include: {'foo/bar.moor'}, tables: [Foo, Bar])
class MyDatabase {}

@UseDao(include: {'package:x/y.moor'})
class MyDao {}
'''),
    ]);

    await _apply();

    await d.dir('app/lib', [
      d.file('a.dart', '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'foo/bar.drift'}, tables: [Foo, Bar])
class MyDatabase {}

@DriftAccessor(include: {'package:x/y.drift'})
class MyDao {}
'''),
    ]).validate();
  });

  _test('patches `.moor.dart` part statements', () async {
    await _setup([
      d.file('a.dart', r'''
import 'package:moor/moor.dart';

part 'a.moor.dart';

@UseDao(
  include: {
    'package:foo_app/db/foo_queries.moor',
  },
)
class FooDao with _$FooDaoMixin {}
'''),
    ]);

    await _apply();

    await d.dir('app/lib', [
      d.file('a.dart', r'''
import 'package:drift/drift.dart';

part 'a.drift.dart';

@DriftAccessor(
  include: {'package:foo_app/db/foo_queries.drift'},
)
class FooDao with _$FooDaoMixin {}
'''),
    ]).validate();
  });

  _test('updates pubspec.yaml', () async {
    await _setup(const [], pubspec: '''
name: app

environment:
  sdk: ^2.12.0

dependencies:
  moor:
  something_else:

# comment
dev_dependencies:
  moor_generator: ^4.5.6
  build_runner: ^2.0.0

dependency_overrides:
  moor:
    path: /foo/bar
  moor_generator:
    hosted: foo
    version: ^1.2.3
''');

    await _apply();

    await d.dir('app', [
      d.file('pubspec.yaml', '''
name: app

environment:
  sdk: ^2.12.0

dependencies:
  drift: ^1.0.0
  something_else:

# comment
dev_dependencies:
  drift_dev: ^1.0.0
  build_runner: ^2.0.0

dependency_overrides:
  drift:
    path: /foo/bar
  drift_dev:
    hosted: foo
    version: ^1.2.3
'''),
    ]).validate();
  });

  _test('transforms build configuration files', () async {
    await _setup(
      const [],
      additional: [
        d.file('build.yaml', r'''
targets:
  $default:
    builders:
      moor_generator:
        options:
          # comment
          compact_query_methods: true
      "moor_generator:foo":
        options:
          bar: baz

  another_target:
    builders:
      moor_generator|moor_generator_not_shared:
        options:
          another: option
''')
      ],
    );

    await _apply();

    await d.dir('app', [
      d.file('build.yaml', r'''
targets:
  $default:
    builders:
      drift_dev:
        options:
          # comment
          compact_query_methods: true
      drift_dev|foo:
        options:
          bar: baz

  another_target:
    builders:
      drift_dev|not_shared:
        options:
          another: option
''')
    ]).validate();
  });

  _test('transforms analysis option files', () async {
    await _setup(
      const [],
      additional: [
        d.file('analysis_options.yaml', '''
# a comment
analyzer:
  plugins:
    # comment 2
    - moor # another
    # another
''')
      ],
    );

    await _apply();

    await d.dir('app', [
      d.file('analysis_options.yaml', r'''
# a comment
analyzer:
  plugins:
    # comment 2
    - drift # another
    # another
''')
    ]).validate();
  });

  _test('transforms moor_flutter usages', () async {
    await _setup(
      [
        d.file('a.dart', r'''
import 'package:moor_flutter/moor_flutter.dart';

part 'a.dart';

@UseMoor(
  include: {
    'package:foo_app/db/foo_queries.moor',
  },
)
class Db extends _$Db {}

QueryExecutor _executor() {
  return FlutterQueryExecutor.inDatabaseFolder(path: 'foo');
}
'''),
      ],
      pubspec: '''
name: app

environment:
  sdk: ^2.12.0

dependencies:
  moor: ^4.4.0
  moor_flutter: ^4.0.0
dev_dependencies:
  moor_generator: ^4.4.0
''',
    );

    await _apply();

    await d.dir(
      'app',
      [
        d.file('pubspec.yaml', '''
name: app

environment:
  sdk: ^2.12.0

dependencies:
  drift: ^1.0.0
  drift_sqflite: ^1.0.0
dev_dependencies:
  drift_dev: ^1.0.0
'''),
        d.dir('lib', [
          d.file('a.dart', r'''
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:drift/drift.dart';

part 'a.dart';

@DriftDatabase(
  include: {'package:foo_app/db/foo_queries.drift'},
)
class Db extends _$Db {}

QueryExecutor _executor() {
  return SqfliteQueryExecutor.inDatabaseFolder(path: 'foo');
}
'''),
        ]),
      ],
    ).validate();
  });
}
