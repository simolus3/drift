import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/data/build_status.dart';

/// For some reason, `build_runner test` doesn't stop even after tests have
/// completed. I couldn't figure out why it does that.
/// So, we're re-implementing it here by first running a build and then running
/// precompiled tests, exiting once we see a line indicating that tests are
/// done.
///
/// The proper way to run ddc tests would be
///
/// ```
///  dart run build_runner test -d -c test -- -p chrome
/// ```
///
/// https://www.xkcd.com/1495/
void main() async {
  final client = await BuildDaemonClient.connect(
    Directory.current.path,
    [Platform.executable, 'run', 'build_runner', 'daemon', '-d', '-c', 'test'],
    logHandler: (log) => print(log.message),
  );

  final directory = await Directory.systemTemp.createTemp('drift');

  client.registerBuildTarget(DefaultBuildTarget((b) {
    b.target = 'test';
    b.outputLocation
      ..output = directory.path
      ..useSymlinks = false
      ..hoist = false;
  }));
  client.startBuild();

  listen:
  await for (final results in client.buildResults) {
    for (final result in results.results) {
      switch (result.status) {
        case BuildStatus.failed:
          print('Could not run build');
          exitCode = 1;
          return;
        case BuildStatus.succeeded:
          print('Build complete');
          break listen;
        case BuildStatus.started:
          break;
      }
    }
  }

  await client.close();

  final process = await Process.start(
    Platform.executable,
    [
      'run',
      'test',
      '--precompiled',
      directory.absolute.path,
      '-p',
      'chrome',
      '-p',
      'firefox',
      '-r',
      'compact',
    ],
  );

  Completer<int> manualExitCode = Completer();

  process.stderr.pipe(stderr);
  final subscription = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    stdout.writeln(line);

    if (line.contains('All tests passed')) {
      print('Stopping with success exit code');

      manualExitCode.complete(0);
    } else if (line.contains('Some tests failed')) {
      print('Stopping with failure exit code');
      manualExitCode.complete(1);
    }
  });

  final result = await Future.any([
    process.exitCode,
    manualExitCode.future.whenComplete(() => subscription.cancel()),
  ]);

  await directory.delete(recursive: true);
  exit(result);
}
