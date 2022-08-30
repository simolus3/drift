import 'package:drift_dev/src/analysis/preprocess_drift.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('finds dart expressions', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.drift': '''
import 'foo.dart';

CREATE TABLE foo (
  bar INTEGER MAPPED BY `const MyConverter()` NOT NULL
);
''',
    });

    final result = await DriftPreprocessor.analyze(
        backend, Uri.parse('package:a/main.drift'));

    expect(result.temporaryDartFile, '''
import 'package:a/foo.dart';
var expr_0 = const MyConverter();
''');
  });

  test('does not emit Dart file if no Dart expressions are used', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.drift': '''
import 'foo.dart';

CREATE TABLE foo (
  bar INTEGER NOT NULL
);
''',
    });

    final result = await DriftPreprocessor.analyze(
        backend, Uri.parse('package:a/main.drift'));

    expect(result.result.declaredTablesAndViews, ['foo']);
    expect(result.temporaryDartFile, isEmpty);
  });

  test('finds nested dart imports', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'b.drift';

CREATE TABLE foo (
  bar INTEGER MAPPED BY `const MyConverter()` NOT NULL
);
''',
      'a|lib/b.drift': '''
import 'c.drift';
''',
      'a|lib/c.drift': '''
import 'import.dart';
''',
    });

    final result = await DriftPreprocessor.analyze(
        backend, Uri.parse('package:a/a.drift'));

    expect(
        result.temporaryDartFile, contains("import 'package:a/import.dart';"));
  });

  test('does not throw for invalid import', () async {
    final backend = TestBackend.inTest({
      'a|lib/a.drift': '''
import 'b.drift';
import 'does_not_exist.drift';

CREATE TABLE foo (
  bar INTEGER MAPPED BY `const MyConverter()` NOT NULL
);
''',
      'a|lib/b.drift': '''
import 'c.drift';
''',
      'a|lib/c.drift': '''
!! invalid file
''',
    });

    final result = await DriftPreprocessor.analyze(
        backend, Uri.parse('package:a/a.drift'));

    // No Dart import found, but also didn't crash analyzing
    expect(result.temporaryDartFile, isNot(contains('import')));
  });

  test('throws if entrypoint does not exist', () {
    final backend = TestBackend.inTest({});

    expect(
      () =>
          DriftPreprocessor.analyze(backend, Uri.parse('package:foo/bar.dart')),
      throwsA(anything),
    );
  });

  test('throws if entrypoint is invalid', () {
    final backend = TestBackend.inTest({
      'a|lib/main.drift': '! this not a valid drift file !',
    });

    expect(
      () =>
          DriftPreprocessor.analyze(backend, Uri.parse('package:a/main.drift')),
      throwsA(anything),
    );
  });
}
