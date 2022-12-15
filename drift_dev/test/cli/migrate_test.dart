import 'dart:async';

import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'utils.dart';

extension on TestDriftProject {
  Future<void> migrateToDrift() async {
    await runDriftCli(['migrate']);
  }
}

Future<TestDriftProject> _setup2(Iterable<d.Descriptor> lib,
    {String? pubspec, Iterable<d.Descriptor>? additional}) {
  return TestDriftProject.create([
    d.dir('lib', lib),
    if (pubspec != null) d.file('pubspec.yaml', pubspec),
    ...?additional,
  ]);
}

void main() {
  test('renames moor files', () async {
    final project = await _setup2([
      d.file('a.moor', "import 'b.moor';"),
      d.file('b.moor', 'CREATE TABLE foo (x TEXT);'),
    ]);

    await project.migrateToDrift();

    await project.validate(d.dir('lib', [
      d.file('a.drift', "import 'b.drift';"),
      d.file('b.drift', 'CREATE TABLE foo (x TEXT);'),
    ]));
  });

  test('patches moor imports', () async {
    final project = await _setup2([
      d.file('a.dart', '''
import 'package:moor/moor.dart' as moor;
import 'package:moor/extensions/moor_ffi.dart';
import 'package:moor/src/some/internal/file.dart';

export 'package:moor/moor_web.dart';
export 'package:moor/fFI.dart';
'''),
    ]);

    await project.migrateToDrift();

    await project.validate(d.dir('lib', [
      d.file('a.dart', '''
import 'package:drift/drift.dart' as moor;
import 'package:drift/extensions/native.dart';
import 'package:drift/src/some/internal/file.dart';

export 'package:drift/web.dart';
export 'package:drift/native.dart';
'''),
    ]));
  });

  test('updates identifier names', () async {
    final project = await _setup2([
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

    await project.migrateToDrift();

    await project.validate(d.dir('lib', [
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
    ]));
  });

  test('patches include args from @UseMoor and @UseDao', () async {
    final project = await _setup2([
      d.file('a.dart', '''
import 'package:moor/moor.dart';

@UseMoor(include: {'foo/bar.moor'}, tables: [Foo, Bar])
class MyDatabase {}

@UseDao(include: {'package:x/y.moor'})
class MyDao {}
'''),
    ]);

    await project.migrateToDrift();

    await project.validate(d.dir('lib', [
      d.file('a.dart', '''
import 'package:drift/drift.dart';

@DriftDatabase(include: {'foo/bar.drift'}, tables: [Foo, Bar])
class MyDatabase {}

@DriftAccessor(include: {'package:x/y.drift'})
class MyDao {}
'''),
    ]));
  });

  test('patches `.moor.dart` part statements', () async {
    final project = await _setup2([
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

    await project.migrateToDrift();

    await project.validate(d.dir('lib', [
      d.file('a.dart', r'''
import 'package:drift/drift.dart';

part 'a.drift.dart';

@DriftAccessor(
  include: {'package:foo_app/db/foo_queries.drift'},
)
class FooDao with _$FooDaoMixin {}
'''),
    ]));
  });

  test('updates pubspec.yaml', () async {
    final project = await _setup2(const [], pubspec: '''
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

    await project.migrateToDrift();

    await project.validate(d.file('pubspec.yaml', '''
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
'''));
  });

  test('transforms build configuration files', () async {
    final project = await _setup2(
      const [],
      additional: [
        d.file('build.yaml', r'''
targets:
  $default:
    builders:
      moor_generator:
        options:
          # comment
          scoped_dart_components: true
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

    await project.migrateToDrift();

    await project.validate(d.file('build.yaml', r'''
targets:
  $default:
    builders:
      drift_dev:
        options:
          # comment
          scoped_dart_components: true
      drift_dev|foo:
        options:
          bar: baz

  another_target:
    builders:
      drift_dev|not_shared:
        options:
          another: option
'''));
  });

  test('transforms analysis option files', () async {
    final project = await _setup2(
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

    await project.migrateToDrift();

    await project.validate(d.file('analysis_options.yaml', r'''
# a comment
analyzer:
  plugins:
    # comment 2
    - drift # another
    # another
'''));
  });

  test('transforms moor_flutter usages', () async {
    final project = await _setup2(
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

    await project.migrateToDrift();

    await project.validateDir(
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
    );
  });
}
