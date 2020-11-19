import 'dart:io';

/// Runs all test files individually.
///
/// For some reason, coverage collection times out when running them all at once
/// with null safety enabled, so this is what we have to do now.
Future<void> main() async {
  final directory = Directory('test');
  var hadFailures = false;

  await for (final entity in directory.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('_test.dart')) continue;

    final process = await Process.start(
        '/home/simon/bin/dart-sdk/beta/bin/dart', [
      '--no-sound-null-safety',
      'run',
      'test',
      '--coverage=coverage',
      entity.path
    ]);
    await Future.wait(
        [stdout.addStream(process.stdout), stderr.addStream(process.stderr)]);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      hadFailures = true;
    }
  }

  exit(hadFailures ? 1 : 0);
}
